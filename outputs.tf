# Authors SHOULD NOT output entire resource objects as these may contain sensitive outputs and the schema can change with API or provider versions
# https://azure.github.io/Azure-Verified-Modules/specs/tf/res/#id-tffr2---category-outputs---additional-terraform-outputs

output "current_kubernetes_version" {
  description = "The current version running on the Azure Kubernetes Managed Cluster"
  value       = azurerm_kubernetes_cluster.this.current_kubernetes_version
}

output "fqdn" {
  description = "The FQDN of the Azure Kubernetes Managed Cluster"
  value       = azurerm_kubernetes_cluster.this.fqdn
}

output "http_application_routing_zone_name" {
  description = "The Zone Name of the HTTP Application Routing"
  value       = azurerm_kubernetes_cluster.this.http_application_routing_zone_name
}

output "identity_principal_id" {
  description = "The Principal ID associated with this Managed Service Identity"
  value       = try(azurerm_kubernetes_cluster.this.identity[0].principal_id, null)
}

output "identity_tenant_id" {
  description = "The Tenant ID associated with this Managed Service Identity"
  value       = try(azurerm_kubernetes_cluster.this.identity[0].tenant_id, null)
}

output "ingress_application_gateway_identity_client_id" {
  description = "The Client ID of the user-defined Managed Identity used by the Application Gateway"
  value       = try(azurerm_kubernetes_cluster.this.ingress_application_gateway[0].ingress_application_gateway_identity[0].client_id, null)
}

output "ingress_application_gateway_identity_object_id" {
  description = "The Object ID of the user-defined Managed Identity used by the Application Gateway"
  value       = try(azurerm_kubernetes_cluster.this.ingress_application_gateway[0].ingress_application_gateway_identity[0].object_id, null)
}

output "ingress_application_gateway_identity_user_assigned_identity_id" {
  description = "The ID of the User Assigned Identity used by the Application Gateway"
  value       = try(azurerm_kubernetes_cluster.this.ingress_application_gateway[0].ingress_application_gateway_identity[0].user_assigned_identity_id, null)
}

output "key_vault_secrets_provider_secret_identity_client_id" {
  description = "The Client ID of the user-defined Managed Identity used by the Secret Provider"
  value       = try(azurerm_kubernetes_cluster.this.key_vault_secrets_provider[0].secret_identity[0].client_id, null)
}

output "key_vault_secrets_provider_secret_identity_object_id" {
  description = "The Object ID of the user-defined Managed Identity used by the Secret Provider"
  value       = azurerm_kubernetes_cluster.this.key_vault_secrets_provider[0].secret_identity[0].object_id
}

output "key_vault_secrets_provider_secret_identity_user_assigned_identity_id" {
  description = "The ID of the User Assigned Identity used by the Secret Provider"
  value       = azurerm_kubernetes_cluster.this.key_vault_secrets_provider[0].secret_identity[0].user_assigned_identity_id
}

output "kube_admin_config" {
  description = "The kube_admin_config block for the Azure Kubernetes Managed Cluster"
  value       = azurerm_kubernetes_cluster.this.kube_admin_config
}

output "kube_admin_config_raw" {
  description = "Raw Kubernetes config for the admin account"
  value       = azurerm_kubernetes_cluster.this.kube_admin_config_raw
}

output "kube_config" {
  description = "The kube_config block for the Azure Kubernetes Managed Cluster"
  value       = azurerm_kubernetes_cluster.this.kube_config
}

output "kube_config_raw" {
  description = "Raw Kubernetes config for the user account"
  value       = azurerm_kubernetes_cluster.this.kube_config_raw
}

output "kubelet_identity_client_id" {
  description = "The Client ID of the user-defined Managed Identity assigned to the Kubelets"
  value       = azurerm_kubernetes_cluster.this.kubelet_identity[0].client_id
}

output "kubelet_identity_object_id" {
  description = "The Object ID of the user-defined Managed Identity assigned to the Kubelets"
  value       = azurerm_kubernetes_cluster.this.kubelet_identity[0].object_id
}

output "kubelet_identity_user_assigned_identity_id" {
  description = "The ID of the User Assigned Identity assigned to the Kubelets"
  value       = azurerm_kubernetes_cluster.this.kubelet_identity[0].user_assigned_identity_id
}

output "load_balancer_profile_effective_outbound_ips" {
  description = "The effective outbound IPs for the load balancer profile"
  value       = try(azurerm_kubernetes_cluster.this.network_profile[0].load_balancer_profile[0].effective_outbound_ips, null)
}

output "nat_gateway_profile_effective_outbound_ips" {
  description = "The effective outbound IPs for the NAT Gateway profile"
  value       = try(azurerm_kubernetes_cluster.this.network_profile[0].nat_gateway_profile[0].effective_outbound_ips, null)
}

output "network_profile" {
  description = "The network profile block for the Kubernetes cluster"
  value       = azurerm_kubernetes_cluster.this.network_profile
}

output "node_resource_group" {
  description = "The auto-generated Resource Group containing resources for the Managed Kubernetes Cluster"
  value       = azurerm_kubernetes_cluster.this.node_resource_group
}

output "node_resource_group_id" {
  description = "The ID of the Resource Group containing resources for the Managed Kubernetes Cluster"
  value       = azurerm_kubernetes_cluster.this.node_resource_group_id
}

output "oidc_issuer_url" {
  description = "The OIDC issuer URL that is associated with the cluster"
  value       = azurerm_kubernetes_cluster.this.oidc_issuer_url
}

output "oms_agent_identity_client_id" {
  description = "The Client ID of the user-defined Managed Identity used by the OMS Agents"
  value       = try(azurerm_kubernetes_cluster.this.oms_agent[0].oms_agent_identity[0].client_id, null)
}

output "oms_agent_identity_object_id" {
  description = "The Object ID of the user-defined Managed Identity used by the OMS Agents"
  value       = try(azurerm_kubernetes_cluster.this.oms_agent[0].oms_agent_identity[0].object_id, null)
}

output "oms_agent_identity_user_assigned_identity_id" {
  description = "The ID of the User Assigned Identity used by the OMS Agents"
  value       = try(azurerm_kubernetes_cluster.this.oms_agent[0].oms_agent_identity[0].user_assigned_identity_id, null)
}

output "portal_fqdn" {
  description = "The FQDN for the Azure Portal resources when private link has been enabled"
  value       = try(azurerm_kubernetes_cluster.this.portal_fqdn, null)
}

output "private_fqdn" {
  description = "The FQDN for the Kubernetes Cluster when private link has been enabled"
  value       = try(azurerm_kubernetes_cluster.this.private_fqdn, null)
}

output "resource_id" {
  description = "The Kubernetes Managed Cluster ID."
  value       = azapi_update_resource.aks_cluster_post_create.id
}

output "web_app_routing_web_app_routing_identity_client_id" {
  description = "The Client ID of the user-defined Managed Identity used for Web App Routing"
  value       = try(azurerm_kubernetes_cluster.this.web_app_routing[0].web_app_routing_identity[0].client_id, null)
}

output "web_app_routing_web_app_routing_identity_object_id" {
  description = "The Object ID of the user-defined Managed Identity used for Web App Routing"
  value       = try(azurerm_kubernetes_cluster.this.web_app_routing[0].web_app_routing_identity[0].object_id, null)
}

output "web_app_routing_web_app_routing_identity_user_assigned_identity_id" {
  description = "The ID of the User Assigned Identity used for Web App Routing"
  value       = try(azurerm_kubernetes_cluster.this.web_app_routing[0].web_app_routing_identity[0].user_assigned_identity_id, null)
}
