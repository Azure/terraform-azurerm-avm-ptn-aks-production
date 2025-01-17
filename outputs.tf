# Authors SHOULD NOT output entire resource objects as these may contain sensitive outputs and the schema can change with API or provider versions
# https://azure.github.io/Azure-Verified-Modules/specs/tf/res/#id-tffr2---category-outputs---additional-terraform-outputs

output "resource_id" {
  description = "The `azurerm_kubernetes_cluster`'s resource id."
  value       = azurerm_kubernetes_cluster.this.id
}
