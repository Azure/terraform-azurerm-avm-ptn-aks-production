module "avm_res_containerregistry_registry" {
  source   = "Azure/avm-res-containerregistry-registry/azurerm"
  version  = "0.4.0"
  for_each = toset(var.acr == null ? [] : ["acr"])

  location            = var.location
  name                = var.acr.name
  resource_group_name = var.resource_group_name
  private_endpoints = {
    primary = {
      private_dns_zone_resource_ids = var.acr.private_dns_zone_resource_ids
      subnet_resource_id            = var.acr.subnet_resource_id
    }
  }
  public_network_access_enabled = false
  sku                           = "Premium"
  zone_redundancy_enabled       = coalesce(var.acr.zone_redundancy_enabled, true)
}

resource "azurerm_role_assignment" "acr" {
  for_each = toset(var.acr == null ? [] : ["acr"])

  principal_id                     = azurerm_kubernetes_cluster.this.kubelet_identity[0].object_id
  scope                            = module.avm_res_containerregistry_registry["acr"].resource_id
  role_definition_name             = "AcrPull"
  skip_service_principal_aad_check = true
}

resource "azurerm_user_assigned_identity" "aks" {
  count = length(var.managed_identities.user_assigned_resource_ids) > 0 ? 0 : 1

  location            = var.location
  name                = "uami-aks"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

data "azurerm_user_assigned_identity" "cluster_identity" {
  name                = split("/", one(local.managed_identities.user_assigned.this.user_assigned_resource_ids))[8]
  resource_group_name = var.resource_group_name
}

resource "azurerm_role_assignment" "network_contributor_on_resource_group" {
  principal_id         = data.azurerm_user_assigned_identity.cluster_identity.principal_id
  scope                = local.network_resource_group_id
  role_definition_name = "Network Contributor"
}

resource "azurerm_role_assignment" "dns_zone_contributor" {
  count = var.private_dns_zone_id_enabled ? 1 : 0

  principal_id         = data.azurerm_user_assigned_identity.cluster_identity.principal_id
  scope                = var.private_dns_zone_id
  role_definition_name = "Private DNS Zone Contributor"
}

resource "azurerm_kubernetes_cluster" "this" {
  location                          = var.location
  name                              = "aks-${var.name}"
  resource_group_name               = var.resource_group_name
  automatic_upgrade_channel         = "patch"
  azure_policy_enabled              = true
  dns_prefix                        = var.name
  kubernetes_version                = var.kubernetes_version
  local_account_disabled            = true
  node_os_upgrade_channel           = "NodeImage"
  oidc_issuer_enabled               = true
  private_cluster_enabled           = true
  private_dns_zone_id               = var.private_dns_zone_id
  role_based_access_control_enabled = true
  sku_tier                          = "Standard"
  tags                              = var.tags
  workload_identity_enabled         = true

  default_node_pool {
    name                    = "agentpool"
    auto_scaling_enabled    = true
    host_encryption_enabled = true
    max_count               = 9
    max_pods                = 110
    min_count               = 3
    node_labels             = var.node_labels
    orchestrator_version    = var.orchestrator_version
    os_disk_type            = var.os_disk_type
    os_sku                  = var.os_sku
    tags                    = merge(var.tags, var.agents_tags)
    vm_size                 = var.default_node_pool_vm_sku
    vnet_subnet_id          = var.network.node_subnet_id
    zones                   = local.default_node_pool_available_zones

    upgrade_settings {
      max_surge = "10%"
    }
  }
  auto_scaler_profile {
    balance_similar_node_groups = true
  }
  azure_active_directory_role_based_access_control {
    admin_group_object_ids = var.rbac_aad_admin_group_object_ids
    azure_rbac_enabled     = var.rbac_aad_azure_rbac_enabled
    tenant_id              = var.rbac_aad_tenant_id
  }
  ## Resources that only support UserAssigned
  dynamic "identity" {
    for_each = local.managed_identities.user_assigned

    content {
      type         = identity.value.type
      identity_ids = identity.value.user_assigned_resource_ids
    }
  }
  key_vault_secrets_provider {
    secret_rotation_enabled = true
  }
  monitor_metrics {
    annotations_allowed = try(var.monitor_metrics.annotations_allowed, null)
    labels_allowed      = try(var.monitor_metrics.labels_allowed, null)
  }
  network_profile {
    network_plugin      = "azure"
    dns_service_ip      = local.dns_service_ip
    load_balancer_sku   = "standard"
    network_data_plane  = var.network_policy == "cilium" ? "cilium" : null
    network_plugin_mode = "overlay"
    network_policy      = var.network_policy
    outbound_type       = var.outbound_type
    pod_cidr            = var.network.pod_cidr
    service_cidr        = var.network.service_cidr
  }
  oms_agent {
    log_analytics_workspace_id      = azurerm_log_analytics_workspace.this.id
    msi_auth_for_monitoring_enabled = true
  }

  lifecycle {
    ignore_changes = [
      kubernetes_version
    ]

    precondition {
      condition     = var.kubernetes_version == null || try(can(regex("^[0-9]+\\.[0-9]+$", var.kubernetes_version)), false)
      error_message = "Ensure that kubernetes_version does not specify a patch version"
    }
    precondition {
      condition     = var.orchestrator_version == null || try(can(regex("^[0-9]+\\.[0-9]+$", var.orchestrator_version)), false)
      error_message = "Ensure that orchestrator_version does not specify a patch version"
    }
    precondition {
      condition     = var.private_dns_zone_id == null ? true : (anytrue([for r in local.valid_private_dns_zone_regexs : try(regex(r, local.private_dns_zone_name) == local.private_dns_zone_name, false)]))
      error_message = "According to the [document](https://learn.microsoft.com/en-us/azure/aks/private-clusters?tabs=azure-portal#configure-a-private-dns-zone), the private DNS zone must be in one of the following format: `privatelink.<region>.azmk8s.io`, `<subzone>.privatelink.<region>.azmk8s.io`, `private.<region>.azmk8s.io`, `<subzone>.private.<region>.azmk8s.io`"
    }
    precondition {
      condition     = var.private_dns_zone_id != null ? var.private_dns_zone_id_enabled == true : var.private_dns_zone_id_enabled == false
      error_message = "private_dns_zone_id must be set if private_dns_zone_id_enabled is true"
    }
  }
}

# The following null_resource is used to trigger the update of the AKS cluster when the kubernetes_version changes
# This is necessary because the azurerm_kubernetes_cluster resource ignores changes to the kubernetes_version attribute
# because AKS patch versions are upgraded automatically by Azure
# The kubernetes_version_keeper and aks_cluster_post_create resources implement a mechanism to force the update
# when the minor kubernetes version changes in var.kubernetes_version

resource "null_resource" "kubernetes_version_keeper" {
  triggers = {
    version = var.kubernetes_version
  }
}

resource "azapi_update_resource" "aks_cluster_post_create" {
  resource_id = azurerm_kubernetes_cluster.this.id
  type        = "Microsoft.ContainerService/managedClusters@2024-02-01"
  body = {
    properties = {
      kubernetesVersion = var.kubernetes_version
    }
  }

  lifecycle {
    ignore_changes       = all
    replace_triggered_by = [null_resource.kubernetes_version_keeper.id]
  }
}

resource "azurerm_log_analytics_workspace" "this" {
  location            = var.location
  name                = "log-${var.name}-aks"
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  tags                = var.tags
}

resource "azurerm_log_analytics_workspace_table" "this" {
  for_each = toset(local.log_analytics_tables)

  name                    = each.value
  workspace_id            = azurerm_log_analytics_workspace.this.id
  plan                    = "Basic"
  total_retention_in_days = 30
}

resource "azurerm_monitor_diagnostic_setting" "aks" {
  name                           = "amds-${var.name}-aks"
  target_resource_id             = azurerm_kubernetes_cluster.this.id
  log_analytics_destination_type = "Dedicated"
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.this.id

  # Kubernetes API Server
  enabled_log {
    category = "kube-apiserver"
  }
  # Kubernetes Audit
  enabled_log {
    category = "kube-audit"
  }
  # Kubernetes Audit Admin Logs
  enabled_log {
    category = "kube-audit-admin"
  }
  # Kubernetes Controller Manager
  enabled_log {
    category = "kube-controller-manager"
  }
  # Kubernetes Scheduler
  enabled_log {
    category = "kube-scheduler"
  }
  #Kubernetes Cluster Autoscaler
  enabled_log {
    category = "cluster-autoscaler"
  }
  #Kubernetes Cloud Controller Manager
  enabled_log {
    category = "cloud-controller-manager"
  }
  #guard
  enabled_log {
    category = "guard"
  }
  #csi-azuredisk-controller
  enabled_log {
    category = "csi-azuredisk-controller"
  }
  #csi-azurefile-controller
  enabled_log {
    category = "csi-azurefile-controller"
  }
  #csi-snapshot-controller
  enabled_log {
    category = "csi-snapshot-controller"
  }
  metric {
    category = "AllMetrics"
  }
}

# required AVM resources interfaces
resource "azurerm_management_lock" "this" {
  count = var.lock != null ? 1 : 0

  lock_level = var.lock.kind
  name       = coalesce(var.lock.name, "lock-${var.lock.kind}")
  scope      = azurerm_kubernetes_cluster.this.id
  notes      = var.lock.kind == "CanNotDelete" ? "Cannot delete the resource or its child resources." : "Cannot delete or modify the resource or its child resources."
}


resource "azurerm_kubernetes_cluster_node_pool" "this" {
  for_each = tomap({
    for pool in local.node_pools : pool.name => pool
  })

  kubernetes_cluster_id = azurerm_kubernetes_cluster.this.id
  name                  = each.value.name
  auto_scaling_enabled  = true
  max_count             = each.value.max_count
  min_count             = each.value.min_count
  node_labels           = each.value.labels
  orchestrator_version  = each.value.orchestrator_version
  os_disk_size_gb       = each.value.os_disk_size_gb
  os_disk_type          = each.value.os_disk_type
  os_sku                = each.value.os_sku
  tags                  = each.value.tags
  vm_size               = each.value.vm_size
  vnet_subnet_id        = var.network.node_subnet_id
  zones                 = each.value.zone

  depends_on = [azapi_update_resource.aks_cluster_post_create]

  lifecycle {
    precondition {
      condition     = can(regex("^[a-z][a-z0-9]{0,11}$", each.value.name))
      error_message = "The name must begin with a lowercase letter, contain only lowercase letters and numbers, and be between 1 and 12 characters in length."
    }
  }
}

# Data source for the current subscription
data "azurerm_subscription" "current" {}

data "azapi_resource_list" "example" {
  parent_id = data.azurerm_subscription.current.id
  type      = "Microsoft.Compute/Skus@2021-07-01"
  query_parameters = {
    "$filter" = [format("location eq '%s'", var.location)]
  }
  response_export_values = ["*"]
}
