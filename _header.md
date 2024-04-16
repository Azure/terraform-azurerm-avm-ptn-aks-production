# terraform-azurerm-avm-ptn-aks-production

### NOTE: This module follows the semantic versioning and versions prior to 1.0.0 should be consider pre-release versions.

This is the Production Standard for AKS pattern module for [Azure Verified Modules (AVM)](https://azure.github.io/Azure-Verified-Modules/) library. This module deploys a production standard AKS cluster along with supporting a Virtual Network and Azure container registry. It provisions an environment sufficient for most production deployments for AKS. It leverages the AzureRM provider and sets a number of initial defaults to minimize the overall inputs for simple configurations.

Major version Zero (0.y.z) is for initial development. Anything MAY change at any time. A module SHOULD NOT be considered stable till at least it is major version one (1.0.0) or greater. Changes will always be via new versions being published and no changes will be made to existing published versions. For more details please go to <https://semver.org/>


## Deployment Steps

1. Set up a GitHub repo environment called `test`.
1. Configure environment protection rule to ensure that approval is required before deploying to this environment.
1. Create a user-assigned managed identity in your test subscription.
1. Create a role assignment for the managed identity on your test subscription, use the minimum required role.
1. Configure federated identity credentials on the user assigned managed identity. Use the GitHub environment.
1. Create the following environment secrets on the `test` environment:
   1. AZURE_CLIENT_ID
   1. AZURE_TENANT_ID
   1. AZURE_SUBSCRIPTION_ID
1. Search and update TODOs within the code and remove the TODO comments once complete.
