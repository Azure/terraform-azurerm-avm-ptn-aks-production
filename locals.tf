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
  agents_availability_zones               = local.isregions_supporting_availability_zones ? [1, 2, 3] : []
  isregions_supporting_availability_zones = contains(local.regions_supporting_availability_zones_azure_cli_names, var.location != null ? var.location : local.resource_group_location)
  regions_supporting_availability_zones_azure_cli_names = [
    "brazilsouth", "francecentral", "qatarcentral", "southafricanorth", "australiaeast",
    "canadacentral", "italynorth", "uaenorth", "centralindia", "centralus", "germanywestcentral",
    "israelcentral", "japaneast", "eastus", "norwayeast", "koreacentral", "eastus2", "northeurope", "southeastasia",
    "southcentralus", "uksouth", "eastasia", "usgovvirginia", "westeurope", "chinanorth3", "westus2", "swedencentral",
  "switzerlandnorth", "polandcentral"]
} 