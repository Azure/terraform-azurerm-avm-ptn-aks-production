// Provider-mocked tests for the log_analytics_workspace input.
// Run with: avm test unit

mock_provider "azapi" {
  mock_data "azapi_resource_list" {
    defaults = {
      output = {
        value = [
          {
            name         = "Standard_D4d_v5"
            resourceType = "virtualMachines"
            locationInfo = [{ location = "eastus2", zones = ["1", "2", "3"] }]
            restrictions = []
          },
        ]
      }
    }
  }
  mock_data "azapi_client_config" {
    defaults = {
      subscription_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000"
    }
  }
}

mock_provider "azurerm" {
  mock_data "azurerm_subscription" {
    defaults = {
      id              = "/subscriptions/00000000-0000-0000-0000-000000000000"
      subscription_id = "00000000-0000-0000-0000-000000000000"
    }
  }

  # Resources that other resources parse as ARM IDs need valid mocked IDs.
  mock_resource "azurerm_log_analytics_workspace" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-aks-test/providers/Microsoft.OperationalInsights/workspaces/log-aks-test-aks"
    }
  }

  mock_resource "azurerm_kubernetes_cluster" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-aks-test/providers/Microsoft.ContainerService/managedClusters/aks-aks-test"
    }
  }
}

mock_provider "null" {}

variables {
  enable_telemetry    = false
  location            = "eastus2"
  name                = "aks-test"
  resource_group_name = "rg-aks-test"
  network = {
    node_subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet/subnets/nodes"
    pod_cidr       = "192.168.0.0/16"
    service_cidr   = "10.2.0.0/16"
  }
  managed_identities = {
    user_assigned_resource_ids = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-aks-test/providers/Microsoft.ManagedIdentity/userAssignedIdentities/uami-aks"]
  }
  rbac_aad_tenant_id = "00000000-0000-0000-0000-000000000000"
}

run "creates_workspace_and_tables_when_no_workspace_id_is_supplied" {
  command = apply

  assert {
    condition     = length(azurerm_log_analytics_workspace.this) == 1
    error_message = "The module should create one Log Analytics workspace when log_analytics_workspace is null."
  }

  assert {
    condition     = azurerm_log_analytics_workspace.this[0].name == "log-aks-test-aks"
    error_message = "The created workspace should keep the log-<name>-aks naming."
  }

  assert {
    condition     = length(azurerm_log_analytics_workspace_table.this) == 4
    error_message = "The module should create the four cluster log tables on the workspace it creates."
  }

  assert {
    condition     = azurerm_monitor_diagnostic_setting.aks.log_analytics_workspace_id == azurerm_log_analytics_workspace.this[0].id
    error_message = "The diagnostic setting should send logs to the created workspace."
  }

  assert {
    condition     = azurerm_kubernetes_cluster.this.oms_agent[0].log_analytics_workspace_id == azurerm_log_analytics_workspace.this[0].id
    error_message = "The AKS oms_agent should use the created workspace."
  }
}

run "uses_supplied_workspace_and_creates_no_workspace_or_tables" {
  command = apply

  variables {
    log_analytics_workspace = {
      resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-existing/providers/Microsoft.OperationalInsights/workspaces/log-existing"
    }
  }

  assert {
    condition     = length(azurerm_log_analytics_workspace.this) == 0
    error_message = "The module should not create a Log Analytics workspace when one is supplied."
  }

  assert {
    condition     = length(azurerm_log_analytics_workspace_table.this) == 0
    error_message = "The module should not create the cluster log tables when a workspace is supplied."
  }

  assert {
    condition     = azurerm_monitor_diagnostic_setting.aks.log_analytics_workspace_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-existing/providers/Microsoft.OperationalInsights/workspaces/log-existing"
    error_message = "The diagnostic setting should send logs to the supplied workspace."
  }

  assert {
    condition     = azurerm_kubernetes_cluster.this.oms_agent[0].log_analytics_workspace_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-existing/providers/Microsoft.OperationalInsights/workspaces/log-existing"
    error_message = "The AKS oms_agent should use the supplied workspace."
  }
}

run "rejects_a_workspace_name_instead_of_a_resource_id" {
  command = plan

  variables {
    log_analytics_workspace = {
      resource_id = "log-existing"
    }
  }

  expect_failures = [
    var.log_analytics_workspace,
  ]
}

run "rejects_a_resource_id_for_another_provider" {
  command = plan

  variables {
    log_analytics_workspace = {
      resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-existing/providers/Microsoft.Network/workspaces/log-existing"
    }
  }

  expect_failures = [
    var.log_analytics_workspace,
  ]
}
