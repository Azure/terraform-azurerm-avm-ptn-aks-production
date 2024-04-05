# Module owners should include the full resource via a 'resource' output
# https://azure.github.io/Azure-Verified-Modules/specs/terraform/#id-tffr2---category-outputs---additional-terraform-outputs
output "resource" {
  description = "This is the full output for the resource."
  value       = azurerm_kubernetes_cluster.this
}

output "resource_id" {
  description = "The `azurerm_kubernetes_cluster`'s resource id."
  value       = azurerm_kubernetes_cluster.this.id
}
