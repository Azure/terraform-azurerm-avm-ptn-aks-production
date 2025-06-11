<!-- BEGIN_TF_DOCS -->
# Default example

This deploys the module  with Azure Bastion.

```hcl
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
  allocation_method   = "Static"
  location            = azurerm_resource_group.this.location
  name                = module.naming.public_ip.name_unique
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "this" {
  location            = azurerm_resource_group.this.location
  name                = module.naming.bastion_host.name_unique
  resource_group_name = azurerm_resource_group.this.name

  ip_configuration {
    name                 = "ipconfig"
    public_ip_address_id = azurerm_public_ip.this.id
    subnet_id            = module.avm_res_network_virtualnetwork.subnets["bastion"].resource_id
  }
}
```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.3.0)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (>= 3.7.0, < 4.0.0)

- <a name="requirement_random"></a> [random](#requirement\_random) (>= 3.5.0, < 4.0.0)

## Resources

The following resources are used by this module:

- [azurerm_bastion_host.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/bastion_host) (resource)
- [azurerm_private_dns_zone.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone) (resource)
- [azurerm_public_ip.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) (resource)
- [azurerm_resource_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) (resource)
- [random_integer.region_index](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/integer) (resource)

<!-- markdownlint-disable MD013 -->
## Required Inputs

No required inputs.

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_enable_telemetry"></a> [enable\_telemetry](#input\_enable\_telemetry)

Description: This variable controls whether or not telemetry is enabled for the module.  
For more information see <https://aka.ms/avm/telemetryinfo>.  
If it is set to false, then no telemetry will be collected.

Type: `bool`

Default: `true`

## Outputs

No outputs.

## Modules

The following Modules are called:

### <a name="module_avm_res_network_virtualnetwork"></a> [avm\_res\_network\_virtualnetwork](#module\_avm\_res\_network\_virtualnetwork)

Source: Azure/avm-res-network-virtualnetwork/azurerm

Version: 0.2.3

### <a name="module_naming"></a> [naming](#module\_naming)

Source: Azure/naming/azurerm

Version: >= 0.3.0

### <a name="module_regions"></a> [regions](#module\_regions)

Source: Azure/regions/azurerm

Version: >= 0.3.0

### <a name="module_test"></a> [test](#module\_test)

Source: ../../

Version:

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->