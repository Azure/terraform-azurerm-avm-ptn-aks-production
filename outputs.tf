output "current_kubernetes_version" {
  description = "The current version running on the Azure Kubernetes Managed Cluster."
  value       = azurerm_kubernetes_cluster.this.current_kubernetes_version
}

output "fqdn" {
  description = "The FQDN of the Azure Kubernetes Managed Cluster."
  value       = azurerm_kubernetes_cluster.this.fqdn
}

output "grafana_url" {
  description = "The URL of the Grafana dashboard, if created by this module."
  value       = try(azurerm_dashboard_grafana.this[0].endpoint, null)
}

output "http_application_routing_zone_name" {
  description = "The Zone Name of the HTTP Application Routing."
  value       = try(azurerm_kubernetes_cluster.this.http_application_routing_zone_name, null)
}

output "identity" {
  description = "The Principal ID and Tenant ID associated with this Managed Service Identity."
  value       = try(azurerm_kubernetes_cluster.this.identity, null)
}

output "ingress_application_gateway" {
  description = "Exported ingress_application_gateway settings associated with the cluster."
  value       = try(azurerm_kubernetes_cluster.this.ingress_application_gateway, null)
}

output "key_vault_secrets_provider" {
  description = "Exported key_vault_secrets_provider settings associated with the cluster."
  value       = try(azurerm_kubernetes_cluster.this.key_vault_secrets_provider[0], null)
}

output "kubelet_identity" {
  description = "The user-defined Managed Identity assigned to the Kubelets."
  value       = try(azurerm_kubernetes_cluster.this.kubelet_identity[0], null)
}

output "name" {
  description = "This is the name of the base resource."
  value       = azurerm_kubernetes_cluster.this.name
}

output "network_profile" {
  description = "Exported network_profile settings associated with the cluster."
  value       = azurerm_kubernetes_cluster.this.network_profile
}

output "node_resource_group" {
  description = "The auto-generated Resource Group which contains the resources for this Managed Kubernetes Cluster."
  value       = azurerm_kubernetes_cluster.this.node_resource_group
}

output "node_resource_group_id" {
  description = "The ID of the Resource Group containing the resources for this Managed Kubernetes Cluster."
  value       = azurerm_kubernetes_cluster.this.node_resource_group_id
}

output "oidc_issuer_url" {
  description = "The OIDC issuer URL that is associated with the cluster."
  value       = azurerm_kubernetes_cluster.this.oidc_issuer_url
}

output "oms_agent" {
  description = "Exported oms_agent settings associated with the cluster."
  value       = try(azurerm_kubernetes_cluster.this.oms_agent, null)
}

output "portal_fqdn" {
  description = "The FQDN for the Azure Portal resources when private link has been enabled, which is only resolvable inside the Virtual Network used by the Kubernetes Cluster."
  value       = try(azurerm_kubernetes_cluster.this.portal_fqdn, null)
}

output "private_fqdn" {
  description = "The FQDN for the Kubernetes Cluster when private link has been enabled, which is only resolvable inside the Virtual Network used by the Kubernetes Cluster."
  value       = try(azurerm_kubernetes_cluster.this.private_fqdn, null)
}

output "resource_id" {
  description = "The `azurerm_kubernetes_cluster`'s resource id."
  value       = azurerm_kubernetes_cluster.this.id
}

output "web_app_routing_identity" {
  description = "Exported web_app_routing_identity settings associated with the cluster."
  value       = try(azapi_update_resource.ingress_profile[0].output.properties.ingressProfile.webAppRouting.identity, null)
}
