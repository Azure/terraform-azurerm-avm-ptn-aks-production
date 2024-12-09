# Managed Prometheus
resource "azurerm_monitor_workspace" "this" {
  # only create the Azure Monitor workspace if monitoring is enabled and an existing Azure Monitor resource ID is not provided
  count = var.azure_monitor_enabled && var.azure_monitor_workspace_resource_id == null ? 1 : 0

  location            = var.location
  name                = local.azure_monitor_name
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_monitor_data_collection_endpoint" "this" {
  count = var.azure_monitor_enabled ? 1 : 0

  location            = var.location
  name                = local.prometheus_dce_name
  resource_group_name = var.resource_group_name
  kind                = "Linux"
  tags                = var.tags
}

resource "azurerm_monitor_data_collection_rule" "prometheus_to_monitor" {
  count = var.azure_monitor_enabled ? 1 : 0

  location                    = var.location
  name                        = local.dcr_prometheus_linux_rule_name
  resource_group_name         = var.resource_group_name
  data_collection_endpoint_id = azurerm_monitor_data_collection_endpoint.this[0].id
  kind                        = "Linux"
  tags                        = var.tags

  data_flow {
    destinations = ["MonitoringAccount1"]
    streams      = ["Microsoft-PrometheusMetrics"]
  }
  destinations {
    monitor_account {
      monitor_account_id = local.azure_monitor_workspace_resource_id
      name               = "MonitoringAccount1"
    }
  }
  data_sources {
    prometheus_forwarder {
      name    = "PrometheusDataSource"
      streams = ["Microsoft-PrometheusMetrics"]
    }
  }
}

resource "azurerm_monitor_data_collection_rule_association" "dcra_prometheus" {
  count = var.azure_monitor_enabled ? 1 : 0

  target_resource_id      = azurerm_kubernetes_cluster.this.id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.prometheus_to_monitor[0].id
  description             = "Association between AKS and Data Collection Rule for Azure Monitor Metrics for Managed Prometheus"
  name                    = local.aks_monitor_association_name
}
