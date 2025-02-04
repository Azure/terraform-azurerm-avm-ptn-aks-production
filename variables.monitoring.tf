variable "action_group_name" {
  description = "The name of the action group."
  type        = string
  default     = null
}

variable "action_group_short_name" {
  description = "The short name of the action group."
  type        = string
  default     = null
  validation {
    condition     = var.action_group_short_name == null || try(length(var.action_group_short_name) <= 12, false)
    error_message = "The action group short name must be 12 characters or less."
  }
}

variable "action_group_email" {
  description = "The email address to use for the action group."
  type        = list(string)
  default     = []
}

variable "dcr_prometheus_linux_rule_name" {
  description = "The name of the data collection rule for Linux."
  type        = string
  default     = null
}

variable "grafana_dashboard_enabled" {
  description = "Whether or not the Grafana dashboard is enabled."
  type        = bool
  default     = true
  nullable    = false
}

variable "azure_monitor_enabled" {
  description = "Whether or not to enable monitoring."
  type        = bool
  default     = true
  nullable    = false
}

variable "grafana_admin_entra_group_id" {
  description = "The ID of the Grafana admin entra group."
  type        = string
  default     = null
}

variable "azure_monitor_name" {
  description = "The name of the Azure monitor workspace."
  type        = string
  default     = null
}

variable "prometheus_dce_name" {
  description = "The name of the Prometheus data collection endpoint."
  type        = string
  default     = null
}

variable "log_analytics_workspace_name" {
  description = "The name of the Log Analytics workspace."
  type        = string
  default     = null
}

variable "grafana_dashboard_name" {
  description = "The name of the Grafana dashboard."
  type        = string
  default     = null
  validation {
    condition     = var.grafana_dashboard_name == null || can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]{0,21}[a-zA-Z0-9]$", var.grafana_dashboard_name))
    error_message = "The Grafana dashboard name must be 2 to 23 characters, containing alphanumerics and hyphens, and must end with an alphanumeric."
  }
}

variable "aks_monitor_association_name" {
  description = "The name of the association between AKS monitor prometheus and the AKS cluster."
  type        = string
  default     = null
}

variable "aks_monitor_ci_association_name" {
  description = "The name of the association between AKS monitor container insights and the AKS cluster."
  type        = string
  default     = null
}

variable "log_analytics_workspace" {
  type = object({
    resource_id = string
  })
  default     = null
  description = "Optional.  The resource ID of an existing Log Analytics Workspace. If not provided, a new one will be created by the module."
}

variable "azure_monitor_workspace_resource_id" {
  type        = string
  default     = null
  description = "Optional.  The resource ID of an existing Azure Monitor Workspace. If not provided, a new one will be created by the module."
}

variable "grafana_dashboard_resource_id" {
  description = "Optional.  The resource ID of an existing Grafana Dashboard. If not provided, a new one will be created by the module."
  type        = string
  default     = null
}
