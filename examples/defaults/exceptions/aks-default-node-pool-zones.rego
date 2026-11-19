package Azure_Proactive_Resiliency_Library_v2

import rego.v1

# Preserve subscription-derived zone selection, accepting fewer than two available zones.
exception contains rules if {
  rules = ["configure_aks_default_node_pool_zones"]
}
