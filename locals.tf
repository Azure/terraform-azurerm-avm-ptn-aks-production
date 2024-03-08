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
  locations_cached_or_live        = data.local_file.locations.content
  regions_by_display_name         = { for v in local.regions_recommended_or_not : v.display_name => v }
  regions_by_name                 = { for v in local.regions_recommended_or_not : v.name => v }
  regions_by_name_or_display_name = merge(local.regions_by_display_name, local.regions_by_name)
  regions_data_merged = [
    for v in jsondecode(local.locations_cached_or_live).value :
    merge(
      {
        name               = v.name
        display_name       = v.displayName
        paired_region_name = try(one(v.metadata.pairedRegion).name, null)
        geography          = v.metadata.geography
        geography_group    = v.metadata.geographyGroup
        recommended        = v.metadata.regionCategory == "Recommended"
      },
      {
        zones = sort(lookup(local.regions_to_zones_map, v.displayName, []))
      }
    ) if v.metadata.regionType == "Physical"
  ]
  # Filter out regions that are not recommended
  regions_recommended_or_not          = [for v in local.regions_data_merged : v if v.recommended]
  regions_to_zones_map                = { for v in local.regions_zonemappings : v.location => v.zones }
  regions_zonemappings                = flatten([for v in jsondecode(local.regions_zonemappings_cached_or_live).resourceTypes : v.zoneMappings if v.resourceType == "virtualMachines"])
  regions_zonemappings_cached_or_live = data.local_file.compute_provider.content
}
locals {
  # Flatten a list of var.node_pools and zones
  node_pools = flatten([
    for pool in var.node_pools : [
      for zone in try(local.regions_by_name_or_display_name[var.location == null ? local.resource_group_location : var.location].zones, ["1"]) : {
        # concatenate name and zone trim to 12 characters
        name    = "${substr(pool.name, 0, 11)}${zone}"
        vm_size = pool.vm_size
        os_sku  = pool.os_sku
        zone    = zone
      }
    ]
  ])
}