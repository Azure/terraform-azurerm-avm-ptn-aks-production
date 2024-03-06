
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
    zones                  = [for zone in local.zones : zone]
  }
  dynamic "identity" {
    for_each = var.identity_ids != null ? [var.identity_ids] : []
    content {
      type         = "UserAssigned"
      identity_ids = var.identity_ids
    }
  }
  key_vault_secrets_provider {
    secret_rotation_enabled = true
  }
}

# required AVM resources interfaces
resource "azurerm_management_lock" "this" {
  count = var.lock.kind != "None" ? 1 : 0

  lock_level = var.lock.kind
  name       = coalesce(var.lock.name, "lock-${var.name}")
  scope      = azurerm_kubernetes_cluster.this.id
}

# resource "azurerm_kubernetes_cluster_node_pool" "this" {
#   # if the region has zone create a node pool per zone
#   # if the region does not have zone create a single node pool with the zone as null
#   # if node pools are not emplty check if the node has a zone if yes then create a node pool per zone otherwise create a single node pool
#   # count = var.node_pools != null ? var.zones ? 3 : 1 : length(local.zones)
#   count = var.node_pools != null ? (var.zones != null ? length(var.node_pools) * 3 : length(var.node_pools)) : 0

#   kubernetes_cluster_id = azurerm_kubernetes_cluster.this.id
#   name                  = "workload${count.index + 1}"
#   vm_size               = try(var.node_pools[count.index].vm_size, var.node_pools[0].vm_size)
#   enable_auto_scaling   = true
#   max_count             = try(var.node_pools[count.index].max_count, var.node_pools[0].max_count)
#   min_count             = try(var.node_pools[count.index].min_count, var.node_pools[0].min_count)
#   os_sku                = try(var.node_pools[count.index].os_sku, var.node_pools[0].os_sku)
#   tags                  = var.tags
#   zones                 = try(formatlist("%s", local.zones[(tonumber(count.index) + 1)]), null)
# }


resource "azurerm_kubernetes_cluster_node_pool" "this" {
  for_each = tomap({
    for pool in local.node_pools : pool.name => pool
  })

  kubernetes_cluster_id = azurerm_kubernetes_cluster.this.id
  name                  = each.value.name
  vm_size               = each.value.vm_size
  enable_auto_scaling   = true
  max_count             = each.value.max_count
  min_count             = each.value.min_count
  os_sku                = each.value.os_sku
  zones                 = [each.value.zone]
  tags                  = var.tags
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

