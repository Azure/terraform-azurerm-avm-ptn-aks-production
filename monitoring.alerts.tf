# Alerting
resource "azurerm_monitor_action_group" "this" {
  name                = local.action_group_name
  resource_group_name = var.resource_group_name
  short_name          = local.action_group_short_name
  tags                = var.tags

  dynamic "email_receiver" {
    for_each = var.action_group_email != null ? { for idx, email in var.action_group_email : idx => email } : {}

    content {
      email_address           = each.value
      name                    = "Email-${each.key}"
      use_common_alert_schema = true
    }
  }
}

resource "azurerm_monitor_metric_alert" "cpu_usage" {
  name                = "CPU Usage Percentage - ${var.name}"
  resource_group_name = var.resource_group_name
  scopes              = [azurerm_kubernetes_cluster.this.id]
  auto_mitigate       = false
  frequency           = "PT5M"
  tags                = var.tags

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

resource "azurerm_monitor_metric_alert" "memory_ws" {
  name                = "Memory Working Set Percentage - ${var.name}"
  resource_group_name = var.resource_group_name
  scopes              = [azurerm_kubernetes_cluster.this.id]
  auto_mitigate       = false
  frequency           = "PT5M"
  tags                = var.tags

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
