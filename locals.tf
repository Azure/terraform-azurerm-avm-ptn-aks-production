# TODO: insert locals here.
locals {
  resource_group_location            = try(data.azurerm_resource_group.parent[0].location, null)
  role_definition_resource_substring = "/providers/Microsoft.Authorization/roleDefinitions"
}

# Private endpoint application security group associations
# Remove if this resource does not support private endpoints
locals {
  private_endpoint_application_security_group_associations = { for assoc in flatten([
    for pe_k, pe_v in var.private_endpoints : [
      for asg_k, asg_v in pe_v.application_security_group_associations : {
        asg_key         = asg_k
        pe_key          = pe_k
        asg_resource_id = asg_v
      }
    ]
  ]) : "${assoc.pe_key}-${assoc.asg_key}" => assoc }
}


locals {
  # regions_supporting_availability_zones = [
  #    "Brazil South", "France Central", "Qatar Central", "South Africa North", "Australia East", 
  #   "Canada Central", "Italy North", "UAE North", "Central India", "Central US", "Germany West Central" , 
  #   "Israel Central", "Japan East", "East US", "Norway East", "Korea Central", "East US 2", "North Europe", "Southeast Asia", 
  #   "South Central US", "UK South", "East Asia", "US Gov Virginia", "West Europe", "China North 3", "West US 2", "Sweden Central", 
  #   "Switzerland North", "Poland Central"]
  # https://github.com/claranet/terraform-azurerm-regions/blob/master/REGIONS.md
  # https://learn.microsoft.com/en-us/azure/reliability/availability-zones-service-support

    regions_map_supporting_availability_zones_azure_cli_names = {
    "Brazil South" = "brazilsouth",
    "France Central" = "francecentral",
    "Qatar Central" = "qatarcentral",
    "South Africa North" = "southafricanorth",
    "Australia East" = "australiaeast",
    "Canada Central" = "canadacentral",
    "Italy North" = "italynorth",
    "UAE North" = "uaenorth",
    "Central India" = "centralindia",
    "Central US" = "centralus",
    "Germany West Central" = "germanywestcentral",
    "Israel Central" = "israelcentral",
    "Japan East" = "japaneast",
    "East US" = "eastus",
    "Norway East" = "norwayeast",
    "Korea Central" = "koreacentral",
    "East US 2" = "eastus2",
    "North Europe" = "northeurope",
    "Southeast Asia" = "southeastasia",
    "South Central US" = "southcentralus",
    "UK South" = "uksouth",
    "East Asia" = "eastasia",
    "US Gov Virginia" = "usgovvirginia",
    "West Europe" = "westeurope",
    "China North 3" = "chinanorth3",
    "West US 2" = "westus2",
    "Sweden Central" = "swedencentral",
    "Switzerland North" = "switzerlandnorth",
    "Poland Central" = "polandcentral"
  }


 isregions_supporting_availability_zones = lookup(local.regions_map_supporting_availability_zones_azure_cli_names, var.location != null ? var.location : local.resource_group_location, null)
 agents_availability_zones =  local.isregions_supporting_availability_zones != null ? [1, 2, 3] : []

} 