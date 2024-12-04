# LAW
resource "azurerm_log_analytics_workspace" "this" {
  name                = local.log_analytics_workspace_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# Grafana
resource "azurerm_dashboard_grafana" "default" {
  count                             = var.grafana_dashboard_name != null ? 1 : 0
  name                              = local.grafana_dashboard_name
  resource_group_name               = var.resource_group_name
  location                          = var.location
  api_key_enabled                   = true
  deterministic_outbound_ip_enabled = false
  public_network_access_enabled     = true
  grafana_major_version             = 10
  identity {
    type = "SystemAssigned"
  }
  azure_monitor_workspace_integrations {
    resource_id = azurerm_monitor_workspace.this.id
  }
}

resource "azurerm_role_assignment" "grafana_reader" {
  scope                = azurerm_dashboard_grafana.default.id
  role_definition_name = "Monitoring Reader"
  principal_id         = azurerm_dashboard_grafana.default.identity[0].principal_id
}

resource "azurerm_role_assignment" "grafana_admin" {
  count                = var.grafana_admin_entra_group_id != null ? 1 : 0
  scope                = azurerm_dashboard_grafana.default.id
  role_definition_name = "Grafana Admin"
  principal_id         = var.grafana_admin_entra_group_id
}

# Managed Prometheus
resource "azurerm_monitor_workspace" "this" {
  name                = local.azure_monitor_name
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_monitor_data_collection_endpoint" "this" {
  name                = local.prometheus_dce_name
  resource_group_name = var.resource_group_name
  location            = var.location
  kind                = "Linux"
}

resource "azurerm_monitor_data_collection_rule" "container-insights" {
  kind                = "Linux"
  location            = var.location
  name                = local.dcr_insights_linux_rule_name
  resource_group_name = var.resource_group_name
  data_flow {
    destinations = ["ciworkspace"]
    streams      = ["Microsoft-ContainerInsights-Group-Default"]
  }
  data_sources {
    extension {
      extension_json = jsonencode({
        dataCollectionSettings = {
          enableContainerLogV2   = true
          interval               = "5m"
          namespaceFilteringMode = "Exclude"
          namespaces             = ["kube-system", "gatekeeper-system", "azure-arc"]
        }
      })
      extension_name = "ContainerInsights"
      name           = "ContainerInsightsExtension"
      streams        = ["Microsoft-ContainerInsights-Group-Default"]
    }
  }
  destinations {
    log_analytics {
      name                  = "ciworkspace"
      workspace_resource_id = azurerm_log_analytics_workspace.this.id
    }
  }
}

resource "azurerm_monitor_data_collection_rule" "prometheus_to_monitor" {
  data_collection_endpoint_id = azurerm_monitor_data_collection_endpoint.this.id
  kind                        = "Linux"
  location                    = var.location
  name                        = local.dcr_prometheus_linux_rule_name
  resource_group_name         = var.resource_group_name
  data_flow {
    destinations = ["MonitoringAccount1"]
    streams      = ["Microsoft-PrometheusMetrics"]
  }
  data_sources {
    prometheus_forwarder {
      name    = "PrometheusDataSource"
      streams = ["Microsoft-PrometheusMetrics"]
    }
  }
  destinations {
    monitor_account {
      monitor_account_id = azurerm_monitor_workspace.this.id
      name               = "MonitoringAccount1"
    }
  }
}

resource "azurerm_monitor_action_group" "this" {
  name                = local.action_group_name
  resource_group_name = var.resource_group_name
  short_name          = local.action_group_short_name
  dynamic "email_receiver" {
    for_each = var.action_group_email != null ? { for idx, email in var.action_group_email : idx => email } : {}
    content {
      email_address           = each.value
      name                    = "Email-${each.key}"
      use_common_alert_schema = true
    }
  }
}

resource "azurerm_monitor_metric_alert" "res-15" {
  auto_mitigate       = false
  frequency           = "PT5M"
  name                = "CPU Usage Percentage - ${var.name}"
  resource_group_name = var.resource_group_name
  scopes              = [azurerm_kubernetes_cluster.this.id]
  action {
    action_group_id = azurerm_monitor_action_group.this.id
  }
  criteria {
    aggregation      = "Average"
    metric_name      = "node_cpu_usage_percentage"
    metric_namespace = "Microsoft.ContainerService/managedClusters"
    operator         = "GreaterThan"
    threshold        = 95
  }
}

resource "azurerm_monitor_metric_alert" "res-16" {
  auto_mitigate       = false
  frequency           = "PT5M"
  name                = "Memory Working Set Percentage - ${var.name}"
  resource_group_name = var.resource_group_name
  scopes              = [azurerm_kubernetes_cluster.this.id]
  action {
    action_group_id = azurerm_monitor_action_group.this.id
  }
  criteria {
    aggregation      = "Average"
    metric_name      = "node_memory_working_set_percentage"
    metric_namespace = "Microsoft.ContainerService/managedClusters"
    operator         = "GreaterThan"
    threshold        = 100
  }
}
