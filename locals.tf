locals {
  resource_group_location            = try(data.azurerm_resource_group.parent[0].location, null)
  role_definition_resource_substring = "/providers/Microsoft.Authorization/roleDefinitions"
}

# Private endpoint application security group associations
# Remove if this resource does not support private endpoints
locals {
  private_endpoint_application_security_group_associations = { for assoc in flatten([
    for pe_k, pe_v in var.private_endpoints : [
      for asg_k, asg_v in pe_v.application_security_group_associations : {
        asg_key         = asg_k
        pe_key          = pe_k
        asg_resource_id = asg_v
      }
    ]
  ]) : "${assoc.pe_key}-${assoc.asg_key}" => assoc }
}


locals {
  # Flatten a list of var.node_pools and zones
  node_pools = flatten([
    for pool in var.node_pools : [
      for zone in local.zones : {
        # concatenate name and zone trim to 12 characters
        name      = "${substr(pool.name, 0, 11)}${zone}"
        vm_size   = pool.vm_size
        max_count = pool.max_count
        min_count = pool.min_count
        os_sku    = pool.os_sku
        zone      = zone
      }
    ]
  ])
  # set of strings 1 2 3
  zones = toset(["1", "2", "3"])
}