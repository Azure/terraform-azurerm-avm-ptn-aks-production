resource "azurerm_monitor_data_collection_rule" "container-insights" {
  location            = var.location
  name                = local.dcr_insights_linux_rule_name
  resource_group_name = var.resource_group_name
  kind                = "Linux"
  tags                = var.tags

  data_flow {
    destinations = ["ciworkspace"]
    streams      = ["Microsoft-ContainerInsights-Group-Default"]
  }
  destinations {
    log_analytics {
      name                  = "ciworkspace"
      workspace_resource_id = local.log_analytics_workspace_resource_id
    }
  }
  data_sources {
    extension {
      extension_name = "ContainerInsights"
      name           = "ContainerInsightsExtension"
      streams        = ["Microsoft-ContainerInsights-Group-Default"]
      extension_json = jsonencode({
        dataCollectionSettings = {
          enableContainerLogV2   = true,
          interval               = "5m",
          namespaceFilteringMode = "Exclude",
          namespaces             = ["kube-system", "gatekeeper-system", "azure-arc"]
        }
      })
    }
  }
}

resource "azurerm_monitor_data_collection_rule_association" "dcra_ci" {
  target_resource_id      = azurerm_kubernetes_cluster.this.id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.container-insights.id
  description             = "Association between AKS and Data Collection Rule for Azure Monitor Metrics for Container Insights.  Deleting this association will break the data collection for this AKS Cluster."
  name                    = local.aks_monitor_ci_association_name
}
