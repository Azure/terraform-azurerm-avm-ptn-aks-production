
data "azurerm_resource_group" "parent" {
  count = var.location == null ? 1 : 0

  name = var.resource_group_name
}

module "regions" {
  source  = "Azure/regions/azurerm"
  version = ">= 0.3.0"
}

resource "azurerm_kubernetes_cluster" "this" {
  location                          = coalesce(var.location, local.resource_group_location)
  name                              = var.name
  resource_group_name               = var.resource_group_name
  automatic_channel_upgrade         = "patch"
  azure_policy_enabled              = true
  dns_prefix                        = var.name
  kubernetes_version                = null
  local_account_disabled            = false
  node_os_channel_upgrade           = "NodeImage"
  oidc_issuer_enabled               = true
  private_cluster_enabled           = true
  role_based_access_control_enabled = true
  sku_tier                          = "Standard"
  tags                              = var.tags
  workload_identity_enabled         = true

  default_node_pool {
    name                = "agentpool"
    vm_size             = "Standard_D4d_v5"
    enable_auto_scaling = true
    # autoscaler profile setting on the old module use the configuration
    enable_host_encryption = true
    max_count              = 5
    max_pods               = 110
    min_count              = 2
    node_count             = 5
    os_sku                 = "Ubuntu"
    tags                   = merge(var.tags, var.agents_tags)
    zones                  =  module.regions.regions_by_name[coalesce(var.location, local.resource_group_location)].zones
  }
  dynamic "identity" {
    for_each = var.identity_ids != null ? [var.identity_ids] : []
    content {
      type         = "UserAssigned"
      identity_ids = var.identity_ids
    }
  }
  dynamic "key_vault_secrets_provider" {
    for_each = var.key_vault_secrets_provider_enabled ? ["key_vault_secrets_provider"] : []

    content {
      secret_rotation_enabled  =true
    }
  }

    dynamic "monitor_metrics" {
  
    for_each = var.monitor_metrics != null ? [var.monitor_metrics] : []

    content {
      annotations_allowed = var.monitor_metrics.annotations_allowed
      labels_allowed      = var.monitor_metrics.labels_allowed
    }
  }
  network_profile {
    network_plugin      = "azure"
    load_balancer_sku   = "standard"
    network_plugin_mode = "overlay"
    network_policy      = "calico"
    outbound_type       = "userAssignedNATGateway"
  }
 dynamic "oms_agent" {
    for_each = var.log_analytics_workspace_enabled ? ["oms_agent"] : []

    content {
      log_analytics_workspace_id      = local.log_analytics_workspace.id
      msi_auth_for_monitoring_enabled = var.msi_auth_for_monitoring_enabled
    }
  }
}

# required AVM resources interfaces
resource "azurerm_management_lock" "this" {
  count = var.lock.kind != "None" ? 1 : 0

  lock_level = var.lock.kind
  name       = coalesce(var.lock.name, "lock-${var.name}")
  scope      = azurerm_kubernetes_cluster.this.id
}

resource "azurerm_kubernetes_cluster_node_pool" "this" {
  # set max nodepools created to 3
  for_each = var.node_pools

  kubernetes_cluster_id = azurerm_kubernetes_cluster.this.id
  name                  = "userpool${each.key}"
  vm_size               = each.value.vm_size
  enable_auto_scaling   = true
  max_count             = each.value.max_count
  min_count             = each.value.min_count
  node_count            = each.value.node_count
  os_sku                = each.value.os_sku
  tags                  = var.tags
  zones                 = formatlist("%s", module.regions.regions_by_name[var.location == null ? local.resource_group_location : var.location].zones[(tonumber(each.key) - 1)])
}
resource "azurerm_role_assignment" "this" {
  for_each = var.role_assignments

  principal_id                           = each.value.principal_id
  scope                                  = azurerm_kubernetes_cluster.this.id
  condition                              = each.value.condition
  condition_version                      = each.value.condition_version
  delegated_managed_identity_resource_id = each.value.delegated_managed_identity_resource_id
  role_definition_id                     = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? each.value.role_definition_id_or_name : null
  role_definition_name                   = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? null : each.value.role_definition_id_or_name
  skip_service_principal_aad_check       = each.value.skip_service_principal_aad_check
}

