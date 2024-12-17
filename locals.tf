locals {
  # Overridable naming conventions - these exist to help reduce the number of required inputs
  action_group_name               = var.action_group_name != null ? var.action_group_name : "ag-${var.name}"
  action_group_short_name         = var.action_group_short_name != null ? var.action_group_short_name : "aks"
  aks_monitor_association_name    = var.aks_monitor_association_name != null ? var.aks_monitor_association_name : "monitor-assoc-${var.name}"
  aks_monitor_ci_association_name = var.aks_monitor_ci_association_name != null ? var.aks_monitor_ci_association_name : "monitor-ci-assoc-${var.name}"
  azure_monitor_name              = var.azure_monitor_name != null ? var.azure_monitor_name : "monitor-${var.name}"
  dcr_insights_linux_rule_name    = var.dcr_prometheus_linux_rule_name != null ? var.dcr_prometheus_linux_rule_name : "dcr-msci-${lower(var.location)}-${var.name}"
  dcr_prometheus_linux_rule_name  = var.dcr_prometheus_linux_rule_name != null ? var.dcr_prometheus_linux_rule_name : "dcr-msprom-${lower(var.location)}-${var.name}"
  diagnostic_settings_name        = var.diagnostic_settings_name != null ? var.diagnostic_settings_name : "amds-${var.name}-aks"
  grafana_dashboard_name          = var.grafana_dashboard_name != null ? var.grafana_dashboard_name : substr(replace("amg${var.name}", "-", ""), 1, 23)
  log_analytics_workspace_name    = var.log_analytics_workspace_name != null ? var.log_analytics_workspace_name : "law-${var.name}"
  prometheus_dce_name             = var.prometheus_dce_name != null ? var.prometheus_dce_name : "dce-msprom-${var.name}"
  user_assigned_identity_name     = var.user_assigned_identity_name != null ? var.user_assigned_identity_name : "uaid-${var.name}"
}

locals {
  # the following resources can be supplied to the module, use the resource ID if supplied, otherwise create the resource if the feature flag is enabled
  azure_monitor_workspace_resource_id = var.azure_monitor_workspace_resource_id != null ? var.azure_monitor_workspace_resource_id : try(azurerm_monitor_workspace.this[0].id, null)
  grafana_dashboard_resource_id       = var.grafana_dashboard_resource_id != null ? var.grafana_dashboard_resource_id : try(azurerm_dashboard_grafana.this[0].id, null)
  log_analytics_workspace_resource_id = var.log_analytics_workspace_resource_id != null ? var.log_analytics_workspace_resource_id : azurerm_log_analytics_workspace.this[0].id
  user_assigned_identity_resource_id  = var.managed_identities.user_assigned_resource_ids != null ? one(var.managed_identities.user_assigned_resource_ids) : azurerm_user_assigned_identity.aks[0].id
}

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
locals {
  web_app_routing_identity_output = var.ingress_profile != null ? {
    object_id   = azapi_update_resource.ingress_profile[0].output.properties.ingressProfile.webAppRouting.identity.objectId
    client_id   = azapi_update_resource.ingress_profile[0].output.properties.ingressProfile.webAppRouting.identity.clientId
    resource_id = azapi_update_resource.ingress_profile[0].output.properties.ingressProfile.webAppRouting.identity.resourceId
  } : null
}
