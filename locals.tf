locals {
  private_dns_zone_name = try(reverse(split("/", var.private_dns_zone_id))[0], null)
  valid_private_dns_zone_regexs = [
    "private\\.[a-z0-9]+\\.azmk8s\\.io",
    "privatelink\\.[a-z0-9]+\\.azmk8s\\.io",
    "[a-zA-Z0-9\\-]{1,32}\\.private\\.[a-z]+\\.azmk8s\\.io",
    "[a-zA-Z0-9\\-]{1,32}\\.privatelink\\.[a-z]+\\.azmk8s\\.io",
  ]
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
      for zone in try(local.regions_by_name_or_display_name[var.location].zones, [""]) : {
        # concatenate name and zone trim to 12 characters
        name                 = "${substr(pool.name, 0, 10)}${zone}"
        vm_size              = pool.vm_size
        orchestrator_version = pool.orchestrator_version
        max_count            = pool.max_count
        min_count            = pool.min_count
        labels               = pool.labels
        node_taints          = pool.node_taints
        os_sku               = pool.os_sku
        mode                 = pool.mode
        os_disk_size_gb      = pool.os_disk_size_gb
        zone                 = zone
      }
    ]
  ])
}
locals {
  log_analytics_tables = ["AKSAudit", "AKSAuditAdmin", "AKSControlPlane", "ContainerLogV2"]
}

# Helper locals to make the dynamic block more readable
# There are three attributes here to cater for resources that
# support both user and system MIs, only system MIs, and only user MIs
locals {
  managed_identities = {
    user_assigned = length(var.managed_identities.user_assigned_resource_ids) > 0 ? {
      this = {
        type                       = "UserAssigned"
        user_assigned_resource_ids = var.managed_identities.user_assigned_resource_ids
      }
      } : {
      this = {
        type                       = "UserAssigned"
        user_assigned_resource_ids = azurerm_user_assigned_identity.aks[*].id
      }
    }
  }
}