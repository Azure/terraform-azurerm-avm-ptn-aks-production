# these are the prometheus rule groups created by the portal when enabling the Insights blade in AKS.
resource "azurerm_monitor_alert_prometheus_rule_group" "UXRecordingRulesRuleGroup" {
  location            = var.location
  name                = "UXRecordingRulesRuleGroup - ${var.name}"
  resource_group_name = var.resource_group_name
  scopes = [
    local.azure_monitor_workspace_resource_id,
    azurerm_kubernetes_cluster.this.id,
  ]
  cluster_name       = var.name
  description        = "UX Recording Rules for Linux"
  interval           = "PT1M"
  rule_group_enabled = true
  tags               = var.tags

  rule {
    expression = "(sum by (namespace, pod, cluster, microsoft_resourceid) (\n\tirate(container_cpu_usage_seconds_total{container != \"\", pod != \"\", job = \"cadvisor\"}[5m])\n)) * on (pod, namespace, cluster, microsoft_resourceid) group_left (node, created_by_name, created_by_kind)\n(max by (node, created_by_name, created_by_kind, pod, namespace, cluster, microsoft_resourceid) (kube_pod_info{pod != \"\", job = \"kube-state-metrics\"}))"
    record     = "ux:pod_cpu_usage:sum_irate"
  }
  rule {
    expression = "sum by (namespace, node, cluster, created_by_name, created_by_kind, microsoft_resourceid) (\nux:pod_cpu_usage:sum_irate\n)\n"
    record     = "ux:controller_cpu_usage:sum_irate"
  }
  rule {
    expression = "(\n\t    sum by (namespace, pod, cluster, microsoft_resourceid) (\n\t\tcontainer_memory_working_set_bytes{container != \"\", pod != \"\", job = \"cadvisor\"}\n\t    )\n\t) * on (pod, namespace, cluster, microsoft_resourceid) group_left (node, created_by_name, created_by_kind)\n(max by (node, created_by_name, created_by_kind, pod, namespace, cluster, microsoft_resourceid) (kube_pod_info{pod != \"\", job = \"kube-state-metrics\"}))"
    record     = "ux:pod_workingset_memory:sum"
  }
  rule {
    expression = "sum by (namespace, node, cluster, created_by_name, created_by_kind, microsoft_resourceid) (\nux:pod_workingset_memory:sum\n)"
    record     = "ux:controller_workingset_memory:sum"
  }
  rule {
    expression = "(\n\t    sum by (namespace, pod, cluster, microsoft_resourceid) (\n\t\tcontainer_memory_rss{container != \"\", pod != \"\", job = \"cadvisor\"}\n\t    )\n\t) * on (pod, namespace, cluster, microsoft_resourceid) group_left (node, created_by_name, created_by_kind)\n(max by (node, created_by_name, created_by_kind, pod, namespace, cluster, microsoft_resourceid) (kube_pod_info{pod != \"\", job = \"kube-state-metrics\"}))"
    record     = "ux:pod_rss_memory:sum"
  }
  rule {
    expression = "sum by (namespace, node, cluster, created_by_name, created_by_kind, microsoft_resourceid) (\nux:pod_rss_memory:sum\n)"
    record     = "ux:controller_rss_memory:sum"
  }
  rule {
    expression = "sum by (node, created_by_name, created_by_kind, namespace, cluster, pod, microsoft_resourceid) (\n(\n(\nsum by (container, pod, namespace, cluster, microsoft_resourceid) (kube_pod_container_info{container != \"\", pod != \"\", container_id != \"\", job = \"kube-state-metrics\"})\nor sum by (container, pod, namespace, cluster, microsoft_resourceid) (kube_pod_init_container_info{container != \"\", pod != \"\", container_id != \"\", job = \"kube-state-metrics\"})\n)\n* on (pod, namespace, cluster, microsoft_resourceid) group_left (node, created_by_name, created_by_kind)\n(\nmax by (node, created_by_name, created_by_kind, pod, namespace, cluster, microsoft_resourceid) (\n\tkube_pod_info{pod != \"\", job = \"kube-state-metrics\"}\n)\n)\n)\n\n)"
    record     = "ux:pod_container_count:sum"
  }
  rule {
    expression = "sum by (node, created_by_name, created_by_kind, namespace, cluster, microsoft_resourceid) (\nux:pod_container_count:sum\n)"
    record     = "ux:controller_container_count:sum"
  }
  rule {
    expression = "max by (node, created_by_name, created_by_kind, namespace, cluster, pod, microsoft_resourceid) (\n(\n(\nmax by (container, pod, namespace, cluster, microsoft_resourceid) (kube_pod_container_status_restarts_total{container != \"\", pod != \"\", job = \"kube-state-metrics\"})\nor sum by (container, pod, namespace, cluster, microsoft_resourceid) (kube_pod_init_status_restarts_total{container != \"\", pod != \"\", job = \"kube-state-metrics\"})\n)\n* on (pod, namespace, cluster, microsoft_resourceid) group_left (node, created_by_name, created_by_kind)\n(\nmax by (node, created_by_name, created_by_kind, pod, namespace, cluster, microsoft_resourceid) (\n\tkube_pod_info{pod != \"\", job = \"kube-state-metrics\"}\n)\n)\n)\n\n)"
    record     = "ux:pod_container_restarts:max"
  }
  rule {
    expression = "max by (node, created_by_name, created_by_kind, namespace, cluster, microsoft_resourceid) (\nux:pod_container_restarts:max\n)"
    record     = "ux:controller_container_restarts:max"
  }
  rule {
    expression = "(sum by (cluster, pod, namespace, resource, microsoft_resourceid) (\n(\n\tmax by (cluster, microsoft_resourceid, pod, container, namespace, resource)\n\t (kube_pod_container_resource_limits{container != \"\", pod != \"\", job = \"kube-state-metrics\"})\n)\n)unless (count by (pod, namespace, cluster, resource, microsoft_resourceid)\n\t(kube_pod_container_resource_limits{container != \"\", pod != \"\", job = \"kube-state-metrics\"})\n!= on (pod, namespace, cluster, microsoft_resourceid) group_left()\n sum by (pod, namespace, cluster, microsoft_resourceid)\n (kube_pod_container_info{container != \"\", pod != \"\", job = \"kube-state-metrics\"}) \n)\n\n)* on (namespace, pod, cluster, microsoft_resourceid) group_left (node, created_by_kind, created_by_name)\n(\n\tkube_pod_info{pod != \"\", job = \"kube-state-metrics\"}\n)"
    record     = "ux:pod_resource_limit:sum"
  }
  rule {
    expression = "sum by (cluster, namespace, created_by_name, created_by_kind, node, resource, microsoft_resourceid) (\nux:pod_resource_limit:sum\n)"
    record     = "ux:controller_resource_limit:sum"
  }
  rule {
    expression = "sum by (cluster, phase, node, created_by_kind, created_by_name, namespace, microsoft_resourceid) ( (\n(kube_pod_status_phase{job=\"kube-state-metrics\",pod!=\"\"})\n or (label_replace((count(kube_pod_deletion_timestamp{job=\"kube-state-metrics\",pod!=\"\"}) by (namespace, pod, cluster, microsoft_resourceid) * count(kube_pod_status_reason{reason=\"NodeLost\", job=\"kube-state-metrics\"} == 0) by (namespace, pod, cluster, microsoft_resourceid)), \"phase\", \"terminating\", \"\", \"\"))) * on (pod, namespace, cluster, microsoft_resourceid) group_left (node, created_by_name, created_by_kind)\n(\nmax by (node, created_by_name, created_by_kind, pod, namespace, cluster, microsoft_resourceid) (\nkube_pod_info{job=\"kube-state-metrics\",pod!=\"\"}\n)\n)\n)"
    record     = "ux:controller_pod_phase_count:sum"
  }
  rule {
    expression = "sum by (cluster, phase, node, namespace, microsoft_resourceid) (\nux:controller_pod_phase_count:sum\n)"
    record     = "ux:cluster_pod_phase_count:sum"
  }
  rule {
    expression = "sum by (instance, cluster, microsoft_resourceid) (\n(1 - irate(node_cpu_seconds_total{job=\"node\", mode=\"idle\"}[5m]))\n)"
    record     = "ux:node_cpu_usage:sum_irate"
  }
  rule {
    expression = "sum by (instance, cluster, microsoft_resourceid) ((\nnode_memory_MemTotal_bytes{job = \"node\"}\n- node_memory_MemFree_bytes{job = \"node\"} \n- node_memory_cached_bytes{job = \"node\"}\n- node_memory_buffers_bytes{job = \"node\"}\n))"
    record     = "ux:node_memory_usage:sum"
  }
  rule {
    expression = "sum by (instance, cluster, microsoft_resourceid) (irate(node_network_receive_drop_total{job=\"node\", device!=\"lo\"}[5m]))"
    record     = "ux:node_network_receive_drop_total:sum_irate"
  }
  rule {
    expression = "sum by (instance, cluster, microsoft_resourceid) (irate(node_network_transmit_drop_total{job=\"node\", device!=\"lo\"}[5m]))"
    record     = "ux:node_network_transmit_drop_total:sum_irate"
  }
}

resource "azurerm_monitor_alert_prometheus_rule_group" "UXRecordingRulesRuleGroup_Windows" {
  location            = var.location
  name                = "UXRecordingRulesRuleGroup-Win - ${var.name}"
  resource_group_name = var.resource_group_name
  scopes = [
    local.azure_monitor_workspace_resource_id,
    azurerm_kubernetes_cluster.this.id,
  ]
  cluster_name       = var.name
  description        = "UX Recording Rules for Windows"
  interval           = "PT1M"
  rule_group_enabled = false
  tags               = var.tags

  rule {
    expression = "sum by (cluster, pod, namespace, node, created_by_kind, created_by_name, microsoft_resourceid) (\n\t(\n\t\tmax by (instance, container_id, cluster, microsoft_resourceid) (\n\t\t\tirate(windows_container_cpu_usage_seconds_total{ container_id != \"\", job = \"windows-exporter\"}[5m])\n\t\t) * on (container_id, cluster, microsoft_resourceid) group_left (container, pod, namespace) (\n\t\t\tmax by (container, container_id, pod, namespace, cluster, microsoft_resourceid) (\n\t\t\t\tkube_pod_container_info{container != \"\", pod != \"\", container_id != \"\", job = \"kube-state-metrics\"}\n\t\t\t)\n\t\t)\n\t) * on (pod, namespace, cluster, microsoft_resourceid) group_left (node, created_by_name, created_by_kind)\n\t(\n\t\tmax by (node, created_by_name, created_by_kind, pod, namespace, cluster, microsoft_resourceid) (\n\t\t  kube_pod_info{ pod != \"\", job = \"kube-state-metrics\"}\n\t\t)\n\t)\n)"
    record     = "ux:pod_cpu_usage_windows:sum_irate"
  }
  rule {
    expression = "sum by (namespace, node, cluster, created_by_name, created_by_kind, microsoft_resourceid) (\nux:pod_cpu_usage_windows:sum_irate\n)\n"
    record     = "ux:controller_cpu_usage_windows:sum_irate"
  }
  rule {
    expression = "sum by (cluster, pod, namespace, node, created_by_kind, created_by_name, microsoft_resourceid) (\n\t(\n\t\tmax by (instance, container_id, cluster, microsoft_resourceid) (\n\t\t\twindows_container_memory_usage_private_working_set_bytes{ container_id != \"\", job = \"windows-exporter\"}\n\t\t) * on (container_id, cluster, microsoft_resourceid) group_left (container, pod, namespace) (\n\t\t\tmax by (container, container_id, pod, namespace, cluster, microsoft_resourceid) (\n\t\t\t\tkube_pod_container_info{container != \"\", pod != \"\", container_id != \"\", job = \"kube-state-metrics\"}\n\t\t\t)\n\t\t)\n\t) * on (pod, namespace, cluster, microsoft_resourceid) group_left (node, created_by_name, created_by_kind)\n\t(\n\t\tmax by (node, created_by_name, created_by_kind, pod, namespace, cluster, microsoft_resourceid) (\n\t\t  kube_pod_info{ pod != \"\", job = \"kube-state-metrics\"}\n\t\t)\n\t)\n)"
    record     = "ux:pod_workingset_memory_windows:sum"
  }
  rule {
    expression = "sum by (namespace, node, cluster, created_by_name, created_by_kind, microsoft_resourceid) (\nux:pod_workingset_memory_windows:sum\n)"
    record     = "ux:controller_workingset_memory_windows:sum"
  }
  rule {
    expression = "sum by (instance, cluster, microsoft_resourceid) (\n(1 - irate(windows_cpu_time_total{job=\"windows-exporter\", mode=\"idle\"}[5m]))\n)"
    record     = "ux:node_cpu_usage_windows:sum_irate"
  }
  rule {
    expression = "sum by (instance, cluster, microsoft_resourceid) ((\nwindows_os_visible_memory_bytes{job = \"windows-exporter\"}\n- windows_memory_available_bytes{job = \"windows-exporter\"}\n))"
    record     = "ux:node_memory_usage_windows:sum"
  }
  rule {
    expression = "sum by (instance, cluster, microsoft_resourceid) (irate(windows_net_packets_received_discarded_total{job=\"windows-exporter\", device!=\"lo\"}[5m]))"
    record     = "ux:node_network_packets_received_drop_total_windows:sum_irate"
  }
  rule {
    expression = "sum by (instance, cluster, microsoft_resourceid) (irate(windows_net_packets_outbound_discarded_total{job=\"windows-exporter\", device!=\"lo\"}[5m]))"
    record     = "ux:node_network_packets_outbound_drop_total_windows:sum_irate"
  }
}

resource "azurerm_monitor_alert_prometheus_rule_group" "NodeRecordingRulesRuleGroup" {
  location            = var.location
  name                = "NodeRecordingRulesRuleGroup-${var.name}"
  resource_group_name = var.resource_group_name
  scopes = [
    local.azure_monitor_workspace_resource_id,
    azurerm_kubernetes_cluster.this.id,
  ]
  cluster_name       = var.name
  description        = "Node Recording Rules RuleGroup"
  interval           = "PT1M"
  rule_group_enabled = true
  tags               = var.tags

  rule {
    expression = "count without (cpu, mode) (  node_cpu_seconds_total{job=\"node\",mode=\"idle\"})"
    record     = "instance:node_num_cpu:sum"
  }
  rule {
    expression = "1 - avg without (cpu) (  sum without (mode) (rate(node_cpu_seconds_total{job=\"node\", mode=~\"idle|iowait|steal\"}[5m])))"
    record     = "instance:node_cpu_utilisation:rate5m"
  }
  rule {
    expression = "(  node_load1{job=\"node\"}/  instance:node_num_cpu:sum{job=\"node\"})"
    record     = "instance:node_load1_per_cpu:ratio"
  }
  rule {
    expression = "1 - (  (    node_memory_MemAvailable_bytes{job=\"node\"}    or    (      node_memory_Buffers_bytes{job=\"node\"}      +      node_memory_Cached_bytes{job=\"node\"}      +      node_memory_MemFree_bytes{job=\"node\"}      +      node_memory_Slab_bytes{job=\"node\"}    )  )/  node_memory_MemTotal_bytes{job=\"node\"})"
    record     = "instance:node_memory_utilisation:ratio"
  }
  rule {
    expression = "rate(node_vmstat_pgmajfault{job=\"node\"}[5m])"
    record     = "instance:node_vmstat_pgmajfault:rate5m"
  }
  rule {
    expression = "rate(node_disk_io_time_seconds_total{job=\"node\", device!=\"\"}[5m])"
    record     = "instance_device:node_disk_io_time_seconds:rate5m"
  }
  rule {
    expression = "rate(node_disk_io_time_weighted_seconds_total{job=\"node\", device!=\"\"}[5m])"
    record     = "instance_device:node_disk_io_time_weighted_seconds:rate5m"
  }
  rule {
    expression = "sum without (device) (  rate(node_network_receive_bytes_total{job=\"node\", device!=\"lo\"}[5m]))"
    record     = "instance:node_network_receive_bytes_excluding_lo:rate5m"
  }
  rule {
    expression = "sum without (device) (  rate(node_network_transmit_bytes_total{job=\"node\", device!=\"lo\"}[5m]))"
    record     = "instance:node_network_transmit_bytes_excluding_lo:rate5m"
  }
  rule {
    expression = "sum without (device) (  rate(node_network_receive_drop_total{job=\"node\", device!=\"lo\"}[5m]))"
    record     = "instance:node_network_receive_drop_excluding_lo:rate5m"
  }
  rule {
    expression = "sum without (device) (  rate(node_network_transmit_drop_total{job=\"node\", device!=\"lo\"}[5m]))"
    record     = "instance:node_network_transmit_drop_excluding_lo:rate5m"
  }
}

resource "azurerm_monitor_alert_prometheus_rule_group" "NodeRecordingRulesRuleGroup_Windows" {
  location            = var.location
  name                = "NodeRecordingRulesRuleGroup-Win-${var.name}"
  resource_group_name = var.resource_group_name
  scopes = [
    local.azure_monitor_workspace_resource_id,
    azurerm_kubernetes_cluster.this.id,
  ]
  cluster_name       = var.name
  description        = "Node Recording Rules RuleGroup for Windows"
  interval           = "PT1M"
  rule_group_enabled = true
  tags               = var.tags

  rule {
    expression = "count (windows_system_system_up_time{job=\"windows-exporter\"})"
    record     = "node:windows_node:sum"
  }
  rule {
    expression = "count by (instance) (sum by (instance, core) (windows_cpu_time_total{job=\"windows-exporter\"}))"
    record     = "node:windows_node_num_cpu:sum"
  }
  rule {
    expression = "1 - avg(rate(windows_cpu_time_total{job=\"windows-exporter\",mode=\"idle\"}[5m]))"
    record     = ":windows_node_cpu_utilisation:avg5m"
  }
  rule {
    expression = "1 - avg by (instance) (rate(windows_cpu_time_total{job=\"windows-exporter\",mode=\"idle\"}[5m]))"
    record     = "node:windows_node_cpu_utilisation:avg5m"
  }
  rule {
    expression = "1 -sum(windows_memory_available_bytes{job=\"windows-exporter\"})/sum(windows_os_visible_memory_bytes{job=\"windows-exporter\"})"
    record     = ":windows_node_memory_utilisation:"
  }
  rule {
    expression = "sum(windows_memory_available_bytes{job=\"windows-exporter\"} + windows_memory_cache_bytes{job=\"windows-exporter\"})"
    record     = ":windows_node_memory_MemFreeCached_bytes:sum"
  }
  rule {
    expression = "(windows_memory_cache_bytes{job=\"windows-exporter\"} + windows_memory_modified_page_list_bytes{job=\"windows-exporter\"} + windows_memory_standby_cache_core_bytes{job=\"windows-exporter\"} + windows_memory_standby_cache_normal_priority_bytes{job=\"windows-exporter\"} + windows_memory_standby_cache_reserve_bytes{job=\"windows-exporter\"})"
    record     = "node:windows_node_memory_totalCached_bytes:sum"
  }
  rule {
    expression = "sum(windows_os_visible_memory_bytes{job=\"windows-exporter\"})"
    record     = ":windows_node_memory_MemTotal_bytes:sum"
  }
  rule {
    expression = "sum by (instance) ((windows_memory_available_bytes{job=\"windows-exporter\"}))"
    record     = "node:windows_node_memory_bytes_available:sum"
  }
  rule {
    expression = "sum by (instance) (windows_os_visible_memory_bytes{job=\"windows-exporter\"})"
    record     = "node:windows_node_memory_bytes_total:sum"
  }
  rule {
    expression = "(node:windows_node_memory_bytes_total:sum - node:windows_node_memory_bytes_available:sum) / scalar(sum(node:windows_node_memory_bytes_total:sum))"
    record     = "node:windows_node_memory_utilisation:ratio"
  }
  rule {
    expression = "1 - (node:windows_node_memory_bytes_available:sum / node:windows_node_memory_bytes_total:sum)"
    record     = "node:windows_node_memory_utilisation:"
  }
  rule {
    expression = "irate(windows_memory_swap_page_operations_total{job=\"windows-exporter\"}[5m])"
    record     = "node:windows_node_memory_swap_io_pages:irate"
  }
  rule {
    expression = "avg(irate(windows_logical_disk_read_seconds_total{job=\"windows-exporter\"}[5m]) + irate(windows_logical_disk_write_seconds_total{job=\"windows-exporter\"}[5m]))"
    record     = ":windows_node_disk_utilisation:avg_irate"
  }
  rule {
    expression = "avg by (instance) ((irate(windows_logical_disk_read_seconds_total{job=\"windows-exporter\"}[5m]) + irate(windows_logical_disk_write_seconds_total{job=\"windows-exporter\"}[5m])))"
    record     = "node:windows_node_disk_utilisation:avg_irate"
  }
}

resource "azurerm_monitor_alert_prometheus_rule_group" "kubernetes-recording-rules-group" {
  location            = var.location
  name                = "KubernetesRecordingRulesRuleGroup-${var.name}"
  resource_group_name = var.resource_group_name
  scopes = [
    local.azure_monitor_workspace_resource_id,
    azurerm_kubernetes_cluster.this.id,
  ]
  cluster_name       = var.name
  description        = "Kubernetes Recording Rules RuleGroup"
  interval           = "PT1M"
  rule_group_enabled = true
  tags               = var.tags

  rule {
    expression = "sum by (cluster, namespace, pod, container) (  irate(container_cpu_usage_seconds_total{job=\"cadvisor\", image!=\"\"}[5m])) * on (cluster, namespace, pod) group_left(node) topk by (cluster, namespace, pod) (  1, max by(cluster, namespace, pod, node) (kube_pod_info{node!=\"\"}))"
    record     = "node_namespace_pod_container:container_cpu_usage_seconds_total:sum_irate"
  }
  rule {
    expression = "container_memory_working_set_bytes{job=\"cadvisor\", image!=\"\"}* on (namespace, pod) group_left(node) topk by(namespace, pod) (1,  max by(namespace, pod, node) (kube_pod_info{node!=\"\"}))"
    record     = "node_namespace_pod_container:container_memory_working_set_bytes"
  }
  rule {
    expression = "container_memory_rss{job=\"cadvisor\", image!=\"\"}* on (namespace, pod) group_left(node) topk by(namespace, pod) (1,  max by(namespace, pod, node) (kube_pod_info{node!=\"\"}))"
    record     = "node_namespace_pod_container:container_memory_rss"
  }
  rule {
    expression = "container_memory_cache{job=\"cadvisor\", image!=\"\"}* on (namespace, pod) group_left(node) topk by(namespace, pod) (1,  max by(namespace, pod, node) (kube_pod_info{node!=\"\"}))"
    record     = "node_namespace_pod_container:container_memory_cache"
  }
  rule {
    expression = "container_memory_swap{job=\"cadvisor\", image!=\"\"}* on (namespace, pod) group_left(node) topk by(namespace, pod) (1,  max by(namespace, pod, node) (kube_pod_info{node!=\"\"}))"
    record     = "node_namespace_pod_container:container_memory_swap"
  }
  rule {
    expression = "kube_pod_container_resource_requests{resource=\"memory\",job=\"kube-state-metrics\"}  * on (namespace, pod, cluster)group_left() max by (namespace, pod, cluster) (  (kube_pod_status_phase{phase=~\"Pending|Running\"} == 1))"
    record     = "cluster:namespace:pod_memory:active:kube_pod_container_resource_requests"
  }
  rule {
    expression = "sum by (namespace, cluster) (    sum by (namespace, pod, cluster) (        max by (namespace, pod, container, cluster) (          kube_pod_container_resource_requests{resource=\"memory\",job=\"kube-state-metrics\"}        ) * on(namespace, pod, cluster) group_left() max by (namespace, pod, cluster) (          kube_pod_status_phase{phase=~\"Pending|Running\"} == 1        )    ))"
    record     = "namespace_memory:kube_pod_container_resource_requests:sum"
  }
  rule {
    expression = "kube_pod_container_resource_requests{resource=\"cpu\",job=\"kube-state-metrics\"}  * on (namespace, pod, cluster)group_left() max by (namespace, pod, cluster) (  (kube_pod_status_phase{phase=~\"Pending|Running\"} == 1))"
    record     = "cluster:namespace:pod_cpu:active:kube_pod_container_resource_requests"
  }
  rule {
    expression = "sum by (namespace, cluster) (    sum by (namespace, pod, cluster) (        max by (namespace, pod, container, cluster) (          kube_pod_container_resource_requests{resource=\"cpu\",job=\"kube-state-metrics\"}        ) * on(namespace, pod, cluster) group_left() max by (namespace, pod, cluster) (          kube_pod_status_phase{phase=~\"Pending|Running\"} == 1        )    ))"
    record     = "namespace_cpu:kube_pod_container_resource_requests:sum"
  }
  rule {
    expression = "kube_pod_container_resource_limits{resource=\"memory\",job=\"kube-state-metrics\"}  * on (namespace, pod, cluster)group_left() max by (namespace, pod, cluster) (  (kube_pod_status_phase{phase=~\"Pending|Running\"} == 1))"
    record     = "cluster:namespace:pod_memory:active:kube_pod_container_resource_limits"
  }
  rule {
    expression = "sum by (namespace, cluster) (    sum by (namespace, pod, cluster) (        max by (namespace, pod, container, cluster) (          kube_pod_container_resource_limits{resource=\"memory\",job=\"kube-state-metrics\"}        ) * on(namespace, pod, cluster) group_left() max by (namespace, pod, cluster) (          kube_pod_status_phase{phase=~\"Pending|Running\"} == 1        )    ))"
    record     = "namespace_memory:kube_pod_container_resource_limits:sum"
  }
  rule {
    expression = "kube_pod_container_resource_limits{resource=\"cpu\",job=\"kube-state-metrics\"}  * on (namespace, pod, cluster)group_left() max by (namespace, pod, cluster) ( (kube_pod_status_phase{phase=~\"Pending|Running\"} == 1) )"
    record     = "cluster:namespace:pod_cpu:active:kube_pod_container_resource_limits"
  }
  rule {
    expression = "sum by (namespace, cluster) (    sum by (namespace, pod, cluster) (        max by (namespace, pod, container, cluster) (          kube_pod_container_resource_limits{resource=\"cpu\",job=\"kube-state-metrics\"}        ) * on(namespace, pod, cluster) group_left() max by (namespace, pod, cluster) (          kube_pod_status_phase{phase=~\"Pending|Running\"} == 1        )    ))"
    record     = "namespace_cpu:kube_pod_container_resource_limits:sum"
  }
  rule {
    expression = "max by (cluster, namespace, workload, pod) (  label_replace(    label_replace(      kube_pod_owner{job=\"kube-state-metrics\", owner_kind=\"ReplicaSet\"},      \"replicaset\", \"$1\", \"owner_name\", \"(.*)\"    ) * on(replicaset, namespace) group_left(owner_name) topk by(replicaset, namespace) (      1, max by (replicaset, namespace, owner_name) (        kube_replicaset_owner{job=\"kube-state-metrics\"}      )    ),    \"workload\", \"$1\", \"owner_name\", \"(.*)\"  ))"
    labels = {
      workload_type = "deployment"
    }
    record = "namespace_workload_pod:kube_pod_owner:relabel"
  }
  rule {
    expression = "max by (cluster, namespace, workload, pod) (  label_replace(    kube_pod_owner{job=\"kube-state-metrics\", owner_kind=\"DaemonSet\"},    \"workload\", \"$1\", \"owner_name\", \"(.*)\"  ))"
    labels = {
      workload_type = "daemonset"
    }
    record = "namespace_workload_pod:kube_pod_owner:relabel"
  }
  rule {
    expression = "max by (cluster, namespace, workload, pod) (  label_replace(    kube_pod_owner{job=\"kube-state-metrics\", owner_kind=\"StatefulSet\"},    \"workload\", \"$1\", \"owner_name\", \"(.*)\"  ))"
    labels = {
      workload_type = "statefulset"
    }
    record = "namespace_workload_pod:kube_pod_owner:relabel"
  }
  rule {
    expression = "max by (cluster, namespace, workload, pod) (  label_replace(    kube_pod_owner{job=\"kube-state-metrics\", owner_kind=\"Job\"},    \"workload\", \"$1\", \"owner_name\", \"(.*)\"  ))"
    labels = {
      workload_type = "job"
    }
    record = "namespace_workload_pod:kube_pod_owner:relabel"
  }
  rule {
    expression = "sum(  node_memory_MemAvailable_bytes{job=\"node\"} or  (    node_memory_Buffers_bytes{job=\"node\"} +    node_memory_Cached_bytes{job=\"node\"} +    node_memory_MemFree_bytes{job=\"node\"} +    node_memory_Slab_bytes{job=\"node\"}  )) by (cluster)"
    record     = ":node_memory_MemAvailable_bytes:sum"
  }
  rule {
    expression = "sum(rate(node_cpu_seconds_total{job=\"node\",mode!=\"idle\",mode!=\"iowait\",mode!=\"steal\"}[5m])) by (cluster) /count(sum(node_cpu_seconds_total{job=\"node\"}) by (cluster, instance, cpu)) by (cluster)"
    record     = "cluster:node_cpu:ratio_rate5m"
  }
}

resource "azurerm_monitor_alert_prometheus_rule_group" "kubernetes-recording-rules-group_Windows" {
  location            = var.location
  name                = "NodeAndK8sRecordingRulesRuleGroup-Win-${var.name}"
  resource_group_name = var.resource_group_name
  scopes = [
    local.azure_monitor_workspace_resource_id,
    azurerm_kubernetes_cluster.this.id,
  ]
  cluster_name       = var.name
  description        = "Node and Kubernetes Recording Rules RuleGroup for Windows"
  interval           = "PT1M"
  rule_group_enabled = false
  tags               = var.tags

  rule {
    expression = "max by (instance,volume)((windows_logical_disk_size_bytes{job=\"windows-exporter\"} - windows_logical_disk_free_bytes{job=\"windows-exporter\"}) / windows_logical_disk_size_bytes{job=\"windows-exporter\"})"
    record     = "node:windows_node_filesystem_usage:"
  }
  rule {
    expression = "max by (instance, volume) (windows_logical_disk_free_bytes{job=\"windows-exporter\"} / windows_logical_disk_size_bytes{job=\"windows-exporter\"})"
    record     = "node:windows_node_filesystem_avail:"
  }
  rule {
    expression = "sum(irate(windows_net_bytes_total{job=\"windows-exporter\"}[5m]))"
    record     = ":windows_node_net_utilisation:sum_irate"
  }
  rule {
    expression = "sum by (instance) ((irate(windows_net_bytes_total{job=\"windows-exporter\"}[5m])))"
    record     = "node:windows_node_net_utilisation:sum_irate"
  }
  rule {
    expression = "sum(irate(windows_net_packets_received_discarded_total{job=\"windows-exporter\"}[5m])) + sum(irate(windows_net_packets_outbound_discarded_total{job=\"windows-exporter\"}[5m]))"
    record     = ":windows_node_net_saturation:sum_irate"
  }
  rule {
    expression = "sum by (instance) ((irate(windows_net_packets_received_discarded_total{job=\"windows-exporter\"}[5m]) + irate(windows_net_packets_outbound_discarded_total{job=\"windows-exporter\"}[5m])))"
    record     = "node:windows_node_net_saturation:sum_irate"
  }
  rule {
    expression = "windows_container_available{job=\"windows-exporter\", container_id != \"\"} * on(container_id) group_left(container, pod, namespace) max(kube_pod_container_info{job=\"kube-state-metrics\", container_id != \"\"}) by(container, container_id, pod, namespace)"
    record     = "windows_pod_container_available"
  }
  rule {
    expression = "windows_container_cpu_usage_seconds_total{job=\"windows-exporter\", container_id != \"\"} * on(container_id) group_left(container, pod, namespace) max(kube_pod_container_info{job=\"kube-state-metrics\", container_id != \"\"}) by(container, container_id, pod, namespace)"
    record     = "windows_container_total_runtime"
  }
  rule {
    expression = "windows_container_memory_usage_commit_bytes{job=\"windows-exporter\", container_id != \"\"} * on(container_id) group_left(container, pod, namespace) max(kube_pod_container_info{job=\"kube-state-metrics\", container_id != \"\"}) by(container, container_id, pod, namespace)"
    record     = "windows_container_memory_usage"
  }
  rule {
    expression = "windows_container_memory_usage_private_working_set_bytes{job=\"windows-exporter\", container_id != \"\"} * on(container_id) group_left(container, pod, namespace) max(kube_pod_container_info{job=\"kube-state-metrics\", container_id != \"\"}) by(container, container_id, pod, namespace)"
    record     = "windows_container_private_working_set_usage"
  }
  rule {
    expression = "windows_container_network_receive_bytes_total{job=\"windows-exporter\", container_id != \"\"} * on(container_id) group_left(container, pod, namespace) max(kube_pod_container_info{job=\"kube-state-metrics\", container_id != \"\"}) by(container, container_id, pod, namespace)"
    record     = "windows_container_network_received_bytes_total"
  }
  rule {
    expression = "windows_container_network_transmit_bytes_total{job=\"windows-exporter\", container_id != \"\"} * on(container_id) group_left(container, pod, namespace) max(kube_pod_container_info{job=\"kube-state-metrics\", container_id != \"\"}) by(container, container_id, pod, namespace)"
    record     = "windows_container_network_transmitted_bytes_total"
  }
  rule {
    expression = "max by (namespace, pod, container) (kube_pod_container_resource_requests{resource=\"memory\",job=\"kube-state-metrics\"}) * on(container,pod,namespace) (windows_pod_container_available)"
    record     = "kube_pod_windows_container_resource_memory_request"
  }
  rule {
    expression = "kube_pod_container_resource_limits{resource=\"memory\",job=\"kube-state-metrics\"} * on(container,pod,namespace) (windows_pod_container_available)"
    record     = "kube_pod_windows_container_resource_memory_limit"
  }
  rule {
    expression = "max by (namespace, pod, container) ( kube_pod_container_resource_requests{resource=\"cpu\",job=\"kube-state-metrics\"}) * on(container,pod,namespace) (windows_pod_container_available)"
    record     = "kube_pod_windows_container_resource_cpu_cores_request"
  }
  rule {
    expression = "kube_pod_container_resource_limits{resource=\"cpu\",job=\"kube-state-metrics\"} * on(container,pod,namespace) (windows_pod_container_available)"
    record     = "kube_pod_windows_container_resource_cpu_cores_limit"
  }
  rule {
    expression = "sum by (namespace, pod, container) (rate(windows_container_total_runtime{}[5m]))"
    record     = "namespace_pod_container:windows_container_cpu_usage_seconds_total:sum_rate"
  }
}
