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
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
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
  location = "East US 2" # Hardcoded because we have to test in a region without availability zones
  name     = module.naming.resource_group.name_unique
}

  

# This is the module call
# Do not specify location here due to the randomization above.
# Leaving location as `null` will cause the module to use the resource group location
# with a data source.
module "test" {
  source              = "../../"
  kubernetes_version  = "1.28"
  enable_telemetry    = var.enable_telemetry # see variables.tf
  name                = module.naming.kubernetes_cluster.name_unique
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  network = {
    name                = module.avm_res_network_virtualnetwork.name
    resource_group_name = azurerm_resource_group.this.name
    node_subnet_id      = module.avm_res_network_virtualnetwork.subnets["subnet"].resource_id
    pod_cidr            = "192.168.0.0/16"
    acr = {
      name                          = module.naming.container_registry.name_unique
      subnet_resource_id            = module.avm_res_network_virtualnetwork.subnets["private_link_subnet"].resource_id
      private_dns_zone_resource_ids = [azurerm_private_dns_zone.this.id]
    }
  }
}

resource "azurerm_private_dns_zone" "this" {
  name                = "privatelink.azurecr.io"
  resource_group_name = azurerm_resource_group.this.name
}

module "avm_res_network_virtualnetwork" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "0.2.3"

  address_space       = ["10.31.0.0/16"]
  location            = azurerm_resource_group.this.location
  name                = "myvnet"
  resource_group_name = azurerm_resource_group.this.name
  subnets = {
    "subnet" = {
      name             = "nodecidr"
      address_prefixes = ["10.31.0.0/17"]
    }
    "private_link_subnet" = {
      name             = "private_link_subnet"
      address_prefixes = ["10.31.129.0/24"]
    }
    "bastion" = {
      name             = "AzureBastionSubnet"
      address_prefixes = ["10.31.128.0/26"]
  }
}
}

resource "azurerm_public_ip" "this" {
  name               = module.naming.public_ip.name_unique
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "this" {
  name = module.naming.bastion_host.name_unique
  location = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  ip_configuration {
    name = "ipconfig"
    subnet_id = module.avm_res_network_virtualnetwork.subnets["bastion"].resource_id
    public_ip_address_id = azurerm_public_ip.this.id
  }
}

