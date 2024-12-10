# Grafana

# todo a simple implementation for now whilst watching progress here - https://github.com/Azure/terraform-azurerm-avm-res-dashboard-grafana
resource "azurerm_dashboard_grafana" "this" {
  count = var.grafana_dashboard_enabled && var.grafana_dashboard_resource_id == null ? 1 : 0

  location                          = var.location
  name                              = local.grafana_dashboard_name
  resource_group_name               = var.resource_group_name
  api_key_enabled                   = true
  deterministic_outbound_ip_enabled = false
  grafana_major_version             = 10
  public_network_access_enabled     = true
  tags                              = var.tags

  azure_monitor_workspace_integrations {
    resource_id = local.azure_monitor_workspace_resource_id
  }
  identity {
    type = "SystemAssigned"
  }
}

# only create the permissions on the Azure Monitor workspace if monitoring is enabled and an existing Azure Monitor resource ID is not provided
# if supplying an existing Monitor Workspace, it is assumed that permissions are already set.
resource "azurerm_role_assignment" "grafana_reader" {
  count = var.grafana_dashboard_enabled && var.azure_monitor_enabled && var.azure_monitor_workspace_resource_id == null ? 1 : 0

  principal_id         = azurerm_dashboard_grafana.this[0].identity[0].principal_id
  scope                = local.azure_monitor_workspace_resource_id
  role_definition_name = "Monitoring Reader"
}

resource "azurerm_role_assignment" "grafana_data_reader" {
  count = var.grafana_dashboard_enabled && var.azure_monitor_enabled && var.azure_monitor_workspace_resource_id == null ? 1 : 0

  principal_id         = azurerm_dashboard_grafana.this[0].identity[0].principal_id
  scope                = local.azure_monitor_workspace_resource_id
  role_definition_name = "Monitoring Data Reader"
}

resource "azurerm_role_assignment" "grafana_admin" {
  count = var.grafana_admin_entra_group_id != null ? 1 : 0

  principal_id         = var.grafana_admin_entra_group_id
  scope                = local.grafana_dashboard_resource_id
  role_definition_name = "Grafana Admin"
}
