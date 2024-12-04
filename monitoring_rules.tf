# these are the rules created by the portal when enabling the Insights blade in AKS.
resource "azurerm_monitor_alert_prometheus_rule_group" "UXRecordingRulesRuleGroup" {
  name                = "UXRecordingRulesRuleGroup - ${var.name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  rule_group_enabled  = true

  description = "UX Recording Rules for Linux"
  scopes = [
    azurerm_monitor_workspace.this.id,
    azurerm_kubernetes_cluster.this.id,
  ]
  cluster_name = var.name
  interval     = "PT1M"

  rule {
    record     = "ux:pod_cpu_usage:sum_irate"
    expression = "(sum by (namespace, pod, cluster, microsoft_resourceid) (irate(container_cpu_usage_seconds_total{container != '', pod != '', job = 'cadvisor'}[5m]))) * on (pod, namespace, cluster, microsoft_resourceid) group_left (node, created_by_name, created_by_kind) (max by (node, created_by_name, created_by_kind, pod, namespace, cluster, microsoft_resourceid) (kube_pod_info{pod != '', job = 'kube-state-metrics'}))"
  }

  rule {
    record     = "ux:controller_cpu_usage:sum_irate"
    expression = "sum by (namespace, node, cluster, created_by_name, created_by_kind, microsoft_resourceid) (ux:pod_cpu_usage:sum_irate)"
  }

  rule {
    record     = "ux:pod_workingset_memory:sum"
    expression = "(sum by (namespace, pod, cluster, microsoft_resourceid) (container_memory_working_set_bytes{container != '', pod != '', job = 'cadvisor'})) * on (pod, namespace, cluster, microsoft_resourceid) group_left (node, created_by_name, created_by_kind) (max by (node, created_by_name, created_by_kind, pod, namespace, cluster, microsoft_resourceid) (kube_pod_info{pod != '', job = 'kube-state-metrics'}))"
  }

  rule {
    record     = "ux:controller_workingset_memory:sum"
    expression = "sum by (namespace, node, cluster, created_by_name, created_by_kind, microsoft_resourceid) (ux:pod_workingset_memory:sum)"
  }

  rule {
    record     = "ux:pod_rss_memory:sum"
    expression = "(sum by (namespace, pod, cluster, microsoft_resourceid) (container_memory_rss{container != '', pod != '', job = 'cadvisor'})) * on (pod, namespace, cluster, microsoft_resourceid) group_left (node, created_by_name, created_by_kind) (max by (node, created_by_name, created_by_kind, pod, namespace, cluster, microsoft_resourceid) (kube_pod_info{pod != '', job = 'kube-state-metrics'}))"
  }

  rule {
    record     = "ux:controller_rss_memory:sum"
    expression = "sum by (namespace, node, cluster, created_by_name, created_by_kind, microsoft_resourceid) (ux:pod_rss_memory:sum)"
  }

  rule {
    record     = "ux:pod_container_count:sum"
    expression = "sum by (node, created_by_name, created_by_kind, namespace, cluster, pod, microsoft_resourceid) ((sum by (container, pod, namespace, cluster, microsoft_resourceid) (kube_pod_container_info{container != '', pod != '', container_id != '', job = 'kube-state-metrics'}) or sum by (container, pod, namespace, cluster, microsoft_resourceid) (kube_pod_init_container_info{container != '', pod != '', container_id != '', job = 'kube-state-metrics'})) * on (pod, namespace, cluster, microsoft_resourceid) group_left (node, created_by_name, created_by_kind) (max by (node, created_by_name, created_by_kind, pod, namespace, cluster, microsoft_resourceid) (kube_pod_info{pod != '', job = 'kube-state-metrics'})))"
  }

  rule {
    record     = "ux:controller_container_count:sum"
    expression = "sum by (node, created_by_name, created_by_kind, namespace, cluster, microsoft_resourceid) (ux:pod_container_count:sum)"
  }

  rule {
    record     = "ux:pod_container_restarts:max"
    expression = "max by (node, created_by_name, created_by_kind, namespace, cluster, pod, microsoft_resourceid) ((max by (container, pod, namespace, cluster, microsoft_resourceid) (kube_pod_container_status_restarts_total{container != '', pod != '', job = 'kube-state-metrics'}) or sum by (container, pod, namespace, cluster, microsoft_resourceid) (kube_pod_init_status_restarts_total{container != '', pod != '', job = 'kube-state-metrics'})) * on (pod, namespace, cluster, microsoft_resourceid) group_left (node, created_by_name, created_by_kind) (max by (node, created_by_name, created_by_kind, pod, namespace, cluster, microsoft_resourceid) (kube_pod_info{pod != '', job = 'kube-state-metrics'})))"
  }

  rule {
    record     = "ux:controller_container_restarts:max"
    expression = "max by (node, created_by_name, created_by_kind, namespace, cluster, microsoft_resourceid) (ux:pod_container_restarts:max)"
  }

  rule {
    record     = "ux:pod_resource_limit:sum"
    expression = "(sum by (cluster, pod, namespace, resource, microsoft_resourceid) (max by (cluster, microsoft_resourceid, pod, container, namespace, resource) (kube_pod_container_resource_limits{container != '', pod != '', job = 'kube-state-metrics'})) unless (count by (pod, namespace, cluster, resource, microsoft_resourceid) (kube_pod_container_resource_limits{container != '', pod != '', job = 'kube-state-metrics'}) != on (pod, namespace, cluster, microsoft_resourceid) group_left() sum by (pod, namespace, cluster, microsoft_resourceid) (kube_pod_container_info{container != '', pod != '', job = 'kube-state-metrics'}))) * on (namespace, pod, cluster, microsoft_resourceid) group_left (node, created_by_kind, created_by_name) (kube_pod_info{pod != '', job = 'kube-state-metrics'})"
  }

  rule {
    record     = "ux:controller_resource_limit:sum"
    expression = "sum by (cluster, namespace, created_by_name, created_by_kind, node, resource, microsoft_resourceid) (ux:pod_resource_limit:sum)"
  }

  rule {
    record     = "ux:controller_pod_phase_count:sum"
    expression = "sum by (cluster, phase, node, created_by_kind, created_by_name, namespace, microsoft_resourceid) ((kube_pod_status_phase{job='kube-state-metrics',pod!=''} or (label_replace((count(kube_pod_deletion_timestamp{job='kube-state-metrics',pod!=''}) by (namespace, pod, cluster, microsoft_resourceid) * count(kube_pod_status_reason{reason='NodeLost', job='kube-state-metrics'} == 0) by (namespace, pod, cluster, microsoft_resourceid)), 'phase', 'terminating', '', ''))) * on (pod, namespace, cluster, microsoft_resourceid) group_left (node, created_by_name, created_by_kind) (max by (node, created_by_name, created_by_kind, pod, namespace, cluster, microsoft_resourceid) (kube_pod_info{job='kube-state-metrics',pod!=''})))"
  }

  rule {
    record     = "ux:cluster_pod_phase_count:sum"
    expression = "sum by (cluster, phase, node, namespace, microsoft_resourceid) (ux:controller_pod_phase_count:sum)"
  }

  rule {
    record     = "ux:node_cpu_usage:sum_irate"
    expression = "sum by (instance, cluster, microsoft_resourceid) ((1 - irate(node_cpu_seconds_total{job='node', mode='idle'}[5m])))"
  }

  rule {
    record     = "ux:node_memory_usage:sum"
    expression = "sum by (instance, cluster, microsoft_resourceid) ((node_memory_MemTotal_bytes{job = 'node'} - node_memory_MemFree_bytes{job = 'node'} - node_memory_cached_bytes{job = 'node'} - node_memory_buffers_bytes{job = 'node'}))"
  }

  rule {
    record     = "ux:node_network_receive_drop_total:sum_irate"
    expression = "sum by (instance, cluster, microsoft_resourceid) (irate(node_network_receive_drop_total{job='node', device!='lo'}[5m]))"
  }

  rule {
    record     = "ux:node_network_transmit_drop_total:sum_irate"
    expression = "sum by (instance, cluster, microsoft_resourceid) (irate(node_network_transmit_drop_total{job='node', device!='lo'}[5m]))"
  }

  tags = var.tags
}

resource "azurerm_monitor_alert_prometheus_rule_group" "UXRecordingRulesRuleGroup_Windows" {
  name                = "UXRecordingRulesRuleGroup-Win - ${var.name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  rule_group_enabled  = false
  description         = "UX Recording Rules for Windows"
  scopes = [
    azurerm_monitor_workspace.this.id,
    azurerm_kubernetes_cluster.this.id,
  ]
  cluster_name = var.name
  interval     = "PT1M"

  rule {
    record     = "ux:pod_cpu_usage_windows:sum_irate"
    expression = "sum by (cluster, pod, namespace, node, created_by_kind, created_by_name, microsoft_resourceid) ((max by (instance, container_id, cluster, microsoft_resourceid) (irate(windows_container_cpu_usage_seconds_total{ container_id != '', job = 'windows-exporter'}[5m])) * on (container_id, cluster, microsoft_resourceid) group_left (container, pod, namespace) (max by (container, container_id, pod, namespace, cluster, microsoft_resourceid) (kube_pod_container_info{container != '', pod != '', container_id != '', job = 'kube-state-metrics'}))) * on (pod, namespace, cluster, microsoft_resourceid) group_left (node, created_by_name, created_by_kind) (max by (node, created_by_name, created_by_kind, pod, namespace, cluster, microsoft_resourceid) (kube_pod_info{ pod != '', job = 'kube-state-metrics'})))"
  }

  rule {
    record     = "ux:controller_cpu_usage_windows:sum_irate"
    expression = "sum by (namespace, node, cluster, created_by_name, created_by_kind, microsoft_resourceid) (ux:pod_cpu_usage_windows:sum_irate)"
  }

  rule {
    record     = "ux:pod_workingset_memory_windows:sum"
    expression = "sum by (cluster, pod, namespace, node, created_by_kind, created_by_name, microsoft_resourceid) ((max by (instance, container_id, cluster, microsoft_resourceid) (windows_container_memory_usage_private_working_set_bytes{ container_id != '', job = 'windows-exporter'}) * on (container_id, cluster, microsoft_resourceid) group_left (container, pod, namespace) (max by (container, container_id, pod, namespace, cluster, microsoft_resourceid) (kube_pod_container_info{container != '', pod != '', container_id != '', job = 'kube-state-metrics'}))) * on (pod, namespace, cluster, microsoft_resourceid) group_left (node, created_by_name, created_by_kind) (max by (node, created_by_name, created_by_kind, pod, namespace, cluster, microsoft_resourceid) (kube_pod_info{ pod != '', job = 'kube-state-metrics'})))"
  }

  rule {
    record     = "ux:controller_workingset_memory_windows:sum"
    expression = "sum by (namespace, node, cluster, created_by_name, created_by_kind, microsoft_resourceid) (ux:pod_workingset_memory_windows:sum)"
  }

  rule {
    record     = "ux:node_cpu_usage_windows:sum_irate"
    expression = "sum by (instance, cluster, microsoft_resourceid) ((1 - irate(windows_cpu_time_total{job='windows-exporter', mode='idle'}[5m])))"
  }

  rule {
    record     = "ux:node_memory_usage_windows:sum"
    expression = "sum by (instance, cluster, microsoft_resourceid) ((windows_os_visible_memory_bytes{job = 'windows-exporter'} - windows_memory_available_bytes{job = 'windows-exporter'}))"
  }

  rule {
    record     = "ux:node_network_packets_received_drop_total_windows:sum_irate"
    expression = "sum by (instance, cluster, microsoft_resourceid) (irate(windows_net_packets_received_discarded_total{job='windows-exporter', device!='lo'}[5m]))"
  }

  rule {
    record     = "ux:node_network_packets_outbound_drop_total_windows:sum_irate"
    expression = "sum by (instance, cluster, microsoft_resourceid) (irate(windows_net_packets_outbound_discarded_total{job='windows-exporter', device!='lo'}[5m]))"
  }

  tags = var.tags
}
