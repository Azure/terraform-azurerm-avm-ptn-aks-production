terraform {
  required_version = ">= 1.3.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4, <5"
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

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = ">= 0.3.0"
}

# This is required for resource modules
resource "azurerm_resource_group" "this" {
  location = "West US" # Hardcoded because we have to test in a region without availability zones
  name     = module.naming.resource_group.name_unique
}

resource "azurerm_user_assigned_identity" "this" {
  location            = azurerm_resource_group.this.location
  name                = module.naming.user_assigned_identity.name_unique
  resource_group_name = azurerm_resource_group.this.name
}

data "azurerm_client_config" "current" {}

# This is the module call
# Do not specify location here due to the randomization above.
module "test" {
  source              = "../../"
  kubernetes_version  = "1.31"
  enable_telemetry    = var.enable_telemetry # see variables.tf
  name                = module.naming.kubernetes_cluster.name_unique
  resource_group_name = azurerm_resource_group.this.name
  network = {
    node_subnet_id = module.avm_res_network_virtualnetwork.subnets["subnet"].resource_id
    pod_cidr       = "192.168.0.0/16"
  }
  managed_identities = {
    user_assigned_resource_ids = [
      azurerm_user_assigned_identity.this.id
    ]
  }
  rbac_aad_admin_group_object_ids = [data.azurerm_client_config.current.object_id]

  location = "AustraliaEast" # Hardcoded because we have to test in a region without availability zones
  node_pools = {
    workload = {
      name                 = "workload"
      vm_size              = "Standard_D2d_v5"
      orchestrator_version = "1.31"
      max_count            = 110
      min_count            = 2
      os_sku               = "AzureLinux"
      mode                 = "User"
    }
  }
}

module "avm_res_network_virtualnetwork" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "0.5.0"

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
  }
}
