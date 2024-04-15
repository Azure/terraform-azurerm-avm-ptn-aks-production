module "regions" {
  source  = "Azure/regions/azurerm"
  version = ">= 0.3.0"
}

resource "random_string" "acr_suffix" {
  length  = 8
  numeric = true
  special = false
  upper   = false
}

resource "azurerm_container_registry" "this" {
  location            = var.location
  name                = "cr${random_string.acr_suffix.result}"
  resource_group_name = var.resource_group_name
  sku                 = "Premium"
  tags                = var.tags
}
resource "azurerm_role_assignment" "acr" {
  principal_id                     = azurerm_kubernetes_cluster.this.kubelet_identity[0].object_id
  scope                            = azurerm_container_registry.this.id
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

resource "azurerm_kubernetes_cluster" "this" {
  location                          = var.location
  name                              = "aks-${var.name}"
  resource_group_name               = var.resource_group_name
  automatic_channel_upgrade         = "patch"
  azure_policy_enabled              = true
  dns_prefix                        = var.name
  kubernetes_version                = var.kubernetes_version
  local_account_disabled            = false
  node_os_channel_upgrade           = "NodeImage"
  oidc_issuer_enabled               = true
  private_cluster_enabled           = true
  role_based_access_control_enabled = true
  sku_tier                          = "Standard"
  tags                              = var.tags
  workload_identity_enabled         = true

  default_node_pool {
    name                   = "agentpool"
    vm_size                = "Standard_D4d_v5"
    enable_auto_scaling    = true
    enable_host_encryption = true
    max_count              = 9
    max_pods               = 110
    min_count              = 3
    orchestrator_version   = var.orchestrator_version
    os_sku                 = "Ubuntu"
    tags                   = merge(var.tags, var.agents_tags)
    vnet_subnet_id         = module.vnet.vnet_subnets_name_id["nodecidr"]
    zones                  = try([for zone in local.regions_by_name_or_display_name[var.location].zones : zone], null)
  }
  auto_scaler_profile {
    balance_similar_node_groups = true
  }
  azure_active_directory_role_based_access_control {
    admin_group_object_ids = var.rbac_aad_admin_group_object_ids
    azure_rbac_enabled     = var.rbac_aad_azure_rbac_enabled
    managed                = true
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
    load_balancer_sku   = "standard"
    network_plugin_mode = "overlay"
    network_policy      = "calico"
    pod_cidr            = var.pod_cidr
  }
  oms_agent {
    log_analytics_workspace_id      = azurerm_log_analytics_workspace.this.id
    msi_auth_for_monitoring_enabled = true
  }

  lifecycle {
    ignore_changes = [
      kubernetes_version
    ]
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
  type = "Microsoft.ContainerService/managedClusters@2023-01-02-preview"
  body = jsonencode({
    properties = {
      kubernetesVersion = var.kubernetes_version
    }
  })
  resource_id = azurerm_kubernetes_cluster.this.id

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

  name         = each.value
  workspace_id = azurerm_log_analytics_workspace.this.id
  plan         = "Basic"
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
  name                  = "np${each.value.name}"
  vm_size               = each.value.vm_size
  enable_auto_scaling   = true
  max_count             = each.value.max_count
  min_count             = each.value.min_count
  orchestrator_version  = each.value.orchestrator_version
  os_sku                = each.value.os_sku
  tags                  = var.tags
  vnet_subnet_id        = module.vnet.vnet_subnets_name_id["nodecidr"]
  zones                 = each.value.zone == "" ? null : [each.value.zone]

  depends_on = [azapi_update_resource.aks_cluster_post_create]
}


# These resources allow the use of consistent local data files, and semver versioning
data "local_file" "compute_provider" {
  filename = "${path.module}/data/microsoft.compute_resourceTypes.json"
}

data "local_file" "locations" {
  filename = "${path.module}/data/locations.json"
}


module "vnet" {
  source  = "Azure/subnets/azurerm"
  version = "1.0.0"

  resource_group_name = var.resource_group_name
  subnets = {
    nodecidr = {
      address_prefixes = var.node_cidr != null ? [var.node_cidr] : ["10.31.0.0/16"]
    }
  }
  virtual_network_address_space = var.node_cidr != null ? [var.node_cidr] : ["10.31.0.0/16"]
  virtual_network_location      = var.location
  virtual_network_name          = "vnet"
}