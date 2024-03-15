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

# This is required for resource modules
resource "azurerm_resource_group" "this" {
  location = "East US 2" # Hardcoded because we have to test in a region with availability zones
  name     = module.naming.resource_group.name_unique
}


# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = ">= 0.3.0"
}

resource "azurerm_user_assigned_identity" "this" {
  location            = azurerm_resource_group.this.location
  name                = "uami-${var.kubernetes_cluster_name}"
  resource_group_name = azurerm_resource_group.this.name
}

locals {
  # Hardcoded instead of using module.regions because the "for_each" map includes keys derived
  # from resource attributes that cannot be determined until apply, and so Terraform cannot determine
  # the full set of keys that will identify the instances of this resource.
  location = "East US 2"
}
module "test" {
  source              = "../../"
  kubernetes_version  = "1.28"
  vnet_subnet_id = lookup(module.vnet.vnet_subnets_name_id, "subnet0")
  enable_telemetry    = var.enable_telemetry # see variables.tf
  name                = module.naming.kubernetes_cluster.name_unique
  resource_group_name = azurerm_resource_group.this.name
  identity_ids        = [azurerm_user_assigned_identity.this.id]
  location            = local.location # Hardcoded because we have to test in a region with availability zones
  node_pools = {
    workload = {
      name                 = "workload"
      vm_size              = "Standard_D2d_v5"
      orchestrator_version = "1.28"
      vnet_subnet_id       = lookup(module.vnet.vnet_subnets_name_id, "workload")
      max_count            = 110
      min_count            = 2
      os_sku               = "Ubuntu"
      mode                 = "User"
    },
    ingress = {
      name                 = "ingress"
      vm_size              = "Standard_D2d_v5"
      orchestrator_version = "1.28"
      vnet_subnet_id       = lookup(module.vnet.vnet_subnets_name_id, "ingress")
      max_count            = 4
      min_count            = 2
      os_sku               = "Ubuntu"
      mode                 = "User"
    }
  }
}

module "vnet" {
  source  = "Azure/subnets/azurerm"
  version = "1.0.0"

  resource_group_name = azurerm_resource_group.this.name
  subnets = {
    subnet0 = {
      address_prefixes  = ["10.52.0.0/16"]
    }
    workload = {
      address_prefixes  = ["10.53.0.0/16"]
    }
    ingress = {
      address_prefixes  = ["10.54.0.0/16"]
    }
  }
  virtual_network_address_space = ["10.0.0.0/8"]
  virtual_network_location      = local.location
  virtual_network_name          = "vnet"
}