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
  for_each            = toset(["1", "2", "3"])
  source              = "../../"
  kubernetes_version  = "1.28"
  vnet_subnet_id      = module.vnet.vnet_subnets_name_id["subnet1"]
  enable_telemetry    = var.enable_telemetry # see variables.tf
  name                = module.naming.kubernetes_cluster.name_unique
  resource_group_name = azurerm_resource_group.this.name
  identity_ids        = [azurerm_user_assigned_identity.this.id]
  subnets             = ["subnet2", "subnet3", "subnet4"]
  location            = local.location # Hardcoded because we have to test in a region with availability zones
  node_pools = {
    workload = {
      name                 = "workload"
      vm_size              = "Standard_D2d_v5"
      orchestrator_version = "1.28"
      vnet_subnet_id       = module.vnet.vnet_subnets_name_id
      max_count            = 110
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
    subnet1 = {
      address_prefixes = ["10.31.0.0/17"]
      nat_gateway = {
        id = azurerm_nat_gateway.example["3"].id
      }
    }
    subnet2 = {
      address_prefixes = ["10.31.128.0/18"]
      nat_gateway = {
        id = azurerm_nat_gateway.example["1"].id
      }
    }
    subnet3 = {
      address_prefixes = ["10.31.192.0/19"]
      nat_gateway = {
        id = azurerm_nat_gateway.example["2"].id
      }

    }
    subnet4 = {
      address_prefixes = ["10.31.224.0/20"]
      nat_gateway = {
        id = azurerm_nat_gateway.example["3"].id
      }
    }
  }
  virtual_network_address_space = ["10.31.0.0/16"]
  virtual_network_location      = local.location
  virtual_network_name          = "vnet"
  depends_on                    = [azurerm_nat_gateway.example]
}


resource "azurerm_nat_gateway" "example" {
  for_each = toset(["1", "2", "3"])

  location            = local.location
  name                = "natgateway${each.key}"
  resource_group_name = azurerm_resource_group.this.name
  sku_name            = "Standard"
  zones               = [each.key]
}


resource "azurerm_nat_gateway_public_ip_prefix_association" "example" {
  for_each = toset(["1", "2", "3"])

  nat_gateway_id      = azurerm_nat_gateway.example[each.key].id
  public_ip_prefix_id = azurerm_public_ip_prefix.example[each.key].id
}

resource "azurerm_public_ip_prefix" "example" {
  for_each = toset(["1", "2", "3"])

  location            = local.location
  name                = "example-PublicIPprefix${each.key}"
  resource_group_name = azurerm_resource_group.this.name
  prefix_length       = 31
  sku                 = "Standard"
  zones               = [each.key]
}