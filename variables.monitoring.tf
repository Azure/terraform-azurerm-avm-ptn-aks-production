variable "action_group_name" {
  description = "The name of the action group."
  type        = string
  default     = null
}

variable "action_group_short_name" {
  description = "The short name of the action group."
  type        = string
  default     = null
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
}

variable "diagnostic_settings_name" {
  description = "The name of the diagnostic settings."
  type        = string
  default     = null
}
