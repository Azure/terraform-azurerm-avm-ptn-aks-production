

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
    zones                  = try([for zone in local.regions_by_name_or_display_name[var.location == null ? local.resource_group_location : var.location].zones : zone], null)
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


resource "azurerm_kubernetes_cluster_node_pool" "this" {
  for_each = tomap({
    for pool in local.node_pools : pool.name => pool
  })

  kubernetes_cluster_id = azurerm_kubernetes_cluster.this.id
  name                  = "${each.value.name}-${var.name}"
  vm_size               = each.value.vm_size
  enable_auto_scaling   = true
  # max_count             = each.value.max_count
  # min_count             = each.value.min_count
  os_sku = each.value.os_sku
  tags   = var.tags
  zones  = [each.value.zone]
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

# These resources allow the use of consistent local data files, and semver versioning
data "local_file" "compute_provider" {
  filename = "${path.module}/data/microsoft.compute_resourceTypes.json"
}

data "local_file" "locations" {
  filename = "${path.module}/data/locations.json"
}