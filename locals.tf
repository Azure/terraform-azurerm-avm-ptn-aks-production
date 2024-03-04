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


# check if zone is available and return the zone if it is available
locals {
  # zones = try(formatlist("%s", module.regions.regions_by_name[var.location == null ? local.resource_group_location : var.location].zones), null)
  zones = {
    for zones in module.regions.regions_by_name_or_display_name[var.location == null ? local.resource_group_location : var.location].zones : zones => zones
  }
}

