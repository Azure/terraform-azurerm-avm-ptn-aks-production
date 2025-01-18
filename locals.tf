locals {
  # Overridable naming conventions - these exist to help reduce the number of required inputs
  action_group_name               = var.action_group_name != null ? var.action_group_name : "ag-${var.name}"
  action_group_short_name         = var.action_group_short_name != null ? var.action_group_short_name : "aks"
  aks_monitor_association_name    = var.aks_monitor_association_name != null ? var.aks_monitor_association_name : "monitor-assoc-${var.name}"
  aks_monitor_ci_association_name = var.aks_monitor_ci_association_name != null ? var.aks_monitor_ci_association_name : "monitor-ci-assoc-${var.name}"
  azure_monitor_name              = var.azure_monitor_name != null ? var.azure_monitor_name : "monitor-${var.name}"
  dcr_insights_linux_rule_name    = var.dcr_prometheus_linux_rule_name != null ? var.dcr_prometheus_linux_rule_name : "dcr-msci-${lower(var.location)}-${var.name}"
  dcr_prometheus_linux_rule_name  = var.dcr_prometheus_linux_rule_name != null ? var.dcr_prometheus_linux_rule_name : "dcr-msprom-${lower(var.location)}-${var.name}"
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
  default_node_pool_available_zones = setsubtract(local.zones, local.restricted_zones)
  filtered_vms = [
    for sku in data.azapi_resource_list.example.output.value :
    sku if(sku.resourceType == "virtualMachines" && sku.name == var.default_node_pool_vm_sku)
  ]
  restricted_zones = try(local.filtered_vms[0].restrictions[0].restrictionInfo.zones, [])
  zones            = local.filtered_vms[0].locationInfo[0].zones
}

locals {
  filtered_vms_by_node_pool = {
    for pool_name, pool in var.node_pools : pool_name => [
      for sku in data.azapi_resource_list.example.output.value :
      sku if(sku.resourceType == "virtualMachines" && sku.name == pool.vm_size)
    ]
  }
  my_node_pool_zones_by_pool = {
    for pool_name, pool in var.node_pools : pool_name => setsubtract(
      local.filtered_vms_by_node_pool[pool_name][0].locationInfo[0].zones,
      try(local.filtered_vms_by_node_pool[pool_name][0].restrictions[0].restrictionInfo.zones, [])
    )
  }
  zonetagged_node_pools = {
    for pool_name, pool in var.node_pools : pool_name => merge(pool, { zones = local.my_node_pool_zones_by_pool[pool_name] })
  }
}


locals {
  # Flatten a list of var.node_pools and zones
  node_pools = flatten([
    for pool in local.zonetagged_node_pools : [
      for zone in pool.zones : {
        # concatenate name and zone trim to 12 characters
        name                 = "${substr(pool.name, 0, 10)}${zone}"
        vm_size              = pool.vm_size
        orchestrator_version = pool.orchestrator_version
        max_count            = pool.max_count
        min_count            = pool.min_count
        tags                 = pool.tags
        labels               = pool.labels
        os_sku               = pool.os_sku
        mode                 = pool.mode
        os_disk_size_gb      = pool.os_disk_size_gb
        zone                 = [zone]
      }
    ]
  ])
}
locals {
  web_app_routing_identity_outputs = var.ingress_profile != null ? {
    object_id                 = azapi_update_resource.ingress_profile[0].output.properties.ingressProfile.webAppRouting.identity.objectId
    client_id                 = azapi_update_resource.ingress_profile[0].output.properties.ingressProfile.webAppRouting.identity.clientId
    user_assigned_identity_id = azapi_update_resource.ingress_profile[0].output.properties.ingressProfile.webAppRouting.identity.resourceId
  } : null
}
