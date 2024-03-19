terraform {
  required_version = ">= 1.3.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.7.0, < 4.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.0, < 4.0.0"
    }
  }
}

provider "azurerm" {
  features {}
}


## Section to provide a random Azure region for the resource group
# This allows us to randomize the region for the resource group.
module "regions" {
  source  = "Azure/regions/azurerm"
  version = ">= 0.3.0"
}

# This allows us to randomize the region for the resource group.
resource "random_integer" "region_index" {
  max = length(module.regions.regions) - 1
  min = 0
}
## End of section to provide a random Azure region for the resource group

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = ">= 0.3.0"
}

# This is required for resource modules
resource "azurerm_resource_group" "this" {
  location = module.regions.regions[random_integer.region_index.result].name
  name     = module.naming.resource_group.name_unique
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
  location = "East US"
}

module "test" {
  source              = "../../"
  kubernetes_version  = "1.28"
  vnet_subnet_id      = module.vnet.vnet_subnets_name_id["subnet0"]
  enable_telemetry    = var.enable_telemetry # see variables.tf
  name                = module.naming.kubernetes_cluster.name_unique
  resource_group_name = azurerm_resource_group.this.name
  location            = local.location
  identity_ids        = [azurerm_user_assigned_identity.this.id]
}

module "vnet" {
  source  = "Azure/subnets/azurerm"
  version = "1.0.0"

  resource_group_name = azurerm_resource_group.this.name
  subnets = {
    subnet0 = {
      address_prefixes = ["10.31.0.0/24"]
      nat_gateway = {
        id = azurerm_nat_gateway.example.id
      }
    }
    subnet1 = {
      address_prefixes = ["10.31.1.0/24"]
      nat_gateway = {
        id = azurerm_nat_gateway.example.id
      }
    }
  }
  virtual_network_address_space = ["10.31.0.0/16"]
  virtual_network_location      = local.location
  virtual_network_name          = "vnet"
}

resource "azurerm_nat_gateway" "example" {
  location            = local.location
  name                = "natgateway"
  resource_group_name = azurerm_resource_group.this.name
}



resource "azurerm_nat_gateway_public_ip_association" "example" {
  nat_gateway_id       = azurerm_nat_gateway.example.id
  public_ip_address_id = azurerm_public_ip.example.id
}

resource "azurerm_public_ip" "example" {
  allocation_method   = "Static"
  location            = local.location
  name                = "example-PIP"
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "Standard"
}