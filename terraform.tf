terraform {
  required_version = ">= 1.3.0"
  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = ">= 1.4.0, < 3.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4, < 5"
    }
    local = {
      source  = "hashicorp/local"
      version = ">=2.4.1, < 3.0"
    }
    modtm = {
      source  = "Azure/modtm"
      version = ">= 0.3, < 1.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.0"
    }
  }
}
