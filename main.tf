
data "azurerm_resource_group" "parent" {
  count = var.location == null ? 1 : 0

  name = var.resource_group_name
}

resource "azurerm_kubernetes_cluster" "this" {
  location                  = coalesce(var.location, local.resource_group_location)
  name                      = var.name
  resource_group_name       = var.resource_group_name
  automatic_channel_upgrade = "patch"
  azure_policy_enabled      = true
  dns_prefix                = var.name
  kubernetes_version        = null
  local_account_disabled    = false
  node_os_channel_upgrade   = "NodeImage"
  oidc_issuer_enabled       = true
  private_cluster_enabled   = true
  # https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster - vnet intergration in preview
  role_based_access_control_enabled = true
  sku_tier                          = "Standard"
  tags                              = merge(var.tags)
  workload_identity_enabled         = true

  default_node_pool {
    name                = "agentpool"
    vm_size             = "Standard_D4d_v5"
    enable_auto_scaling = true
    max_count           = 5
    max_pods            = 110
    min_count           = 2
    # node_count although we agreed on 64 - this has to be a number between min_count and max_count
    node_count = 5
    os_sku     = "Ubuntu"
    # os_disk_size_gb - check the GB size of the disk? TODO: research the default size
    tags = merge(var.tags, var.agents_tags)
  }
  dynamic "identity" {
    for_each = var.client_id == "" || var.client_secret == "" ? ["identity"] : []

    content {
      type         = var.identity_type
      identity_ids = var.identity_ids
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
