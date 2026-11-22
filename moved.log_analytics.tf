# The Log Analytics workspace gained a count so that it can be skipped when an existing workspace is supplied.
# This moves the existing workspace in state to its first instance, so existing deployments keep the workspace and do not recreate it.
moved {
  from = azurerm_log_analytics_workspace.this
  to   = azurerm_log_analytics_workspace.this[0]
}
