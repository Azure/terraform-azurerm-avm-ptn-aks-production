terraform {
  required_version = ">= 1.3.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.7.0, < 4.0.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = ">= 0.3.0"
}

# This is required for resource modules
resource "azurerm_resource_group" "this" {
  location = "West US"
  name     = module.naming.resource_group.name_unique
}

resource "azurerm_user_assigned_identity" "this" {
  location            = azurerm_resource_group.this.location
  name                = "uami-${var.kubernetes_cluster_name}"
  resource_group_name = azurerm_resource_group.this.name
}

# This is the module call
# Do not specify location here due to the randomization above.
# Leaving location as `null` will cause the module to use the resource group location
# with a data source.
module "test" {
  source = "../../"
  # source             = "Azure/avm-<res/ptn>-<name>/azurerm"
  # ...
  enable_telemetry    = var.enable_telemetry # see variables.tf
  name                = module.naming.kubernetes_cluster.name_unique
  resource_group_name = azurerm_resource_group.this.name
  identity_ids        = [azurerm_user_assigned_identity.this.id]
  location            = "West US"
  node_pools = {
    workload = {
      name      = "workload"
      vm_size   = "Standard_D4d_v5"
      max_count = 110
      min_count = 2
      os_sku    = "Ubuntu"
      mode      = "User"
    },
    ingress = {
      name      = "ingress"
      vm_size   = "Standard_D4d_v5"
      max_count = 4
      min_count = 2
      os_sku    = "Ubuntu"
      mode      = "User"
    }
  }
}
