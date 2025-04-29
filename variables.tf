variable "location" {
  type        = string
  description = "The Azure region where the resources should be deployed."
  nullable    = false
}

variable "name" {
  type        = string
  description = "The name for the AKS resources created in the specified Azure Resource Group. This variable overwrites the 'prefix' var (The 'prefix' var will still be applied to the dns_prefix if it is set)"

  validation {
    condition     = can(regex("^[a-zA-Z0-9]$|^[a-zA-Z0-9][-_a-zA-Z0-9]{0,61}[a-zA-Z0-9]$", var.name))
    error_message = "Check naming rules here https://learn.microsoft.com/en-us/rest/api/aks/managed-clusters/create-or-update?view=rest-aks-2023-10-01&tabs=HTTP"
  }
}

variable "network" {
  type = object({
    node_subnet_id = string
    pod_cidr       = string
    service_cidr   = optional(string)
    dns_service_ip = optional(string)
  })
  description = "Values for the networking configuration of the AKS cluster"
}

# This is required for most resource modules
variable "resource_group_name" {
  type        = string
  description = "The resource group where the resources will be deployed."
  nullable    = false
}

variable "acr" {
  type = object({
    name                          = string
    private_dns_zone_resource_ids = set(string)
    subnet_resource_id            = string
    zone_redundancy_enabled       = optional(bool)
  })
  default     = null
  description = "(Optional) Parameters for the Azure Container Registry to use with the Kubernetes Cluster."
}

variable "agents_tags" {
  type        = map(string)
  default     = {}
  description = "(Optional) A mapping of tags to assign to the Node Pool."
}

variable "default_node_pool_vm_sku" {
  type        = string
  default     = "Standard_D4d_v5"
  description = "The VM SKU to use for the default node pool. A minimum of three nodes of 8 vCPUs or two nodes of at least 16 vCPUs is recommended. Do not use SKUs with less than 4 CPUs and 4Gb of memory."
}

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see <https://aka.ms/avm/telemetryinfo>.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
}

variable "kubernetes_version" {
  type        = string
  default     = null
  description = "Specify which Kubernetes release to use. Specify only minor version, such as '1.28'."
}

variable "lock" {
  type = object({
    kind = string
    name = optional(string, null)
  })
  default     = null
  description = <<DESCRIPTION
  Controls the Resource Lock configuration for this resource. The following properties can be specified:

  - `kind` - (Required) The type of lock. Possible values are `\"CanNotDelete\"` and `\"ReadOnly\"`.
  - `name` - (Optional) The name of the lock. If not specified, a name will be generated based on the `kind` value. Changing this forces the creation of a new resource.
  DESCRIPTION

  validation {
    condition     = var.lock != null ? contains(["CanNotDelete", "ReadOnly"], var.lock.kind) : true
    error_message = "Lock kind must be either `\"CanNotDelete\"` or `\"ReadOnly\"`."
  }
}

# tflint-ignore: terraform_unused_declarations
variable "managed_identities" {
  type = object({
    system_assigned            = optional(bool, false)
    user_assigned_resource_ids = optional(set(string), [])
  })
  default     = {}
  description = <<DESCRIPTION
  Controls the Managed Identity configuration on this resource. The following properties can be specified:

  - `system_assigned` - (Optional) Specifies if the System Assigned Managed Identity should be enabled.
  - `user_assigned_resource_ids` - (Optional) Specifies a list of User Assigned Managed Identity resource IDs to be assigned to this resource.
  DESCRIPTION
  nullable    = false
}

variable "monitor_metrics" {
  type = object({
    annotations_allowed = optional(string)
    labels_allowed      = optional(string)
  })
  default     = null
  description = <<-EOT
  (Optional) Specifies a Prometheus add-on profile for the Kubernetes Cluster
  object({
    annotations_allowed = "(Optional) Specifies a comma-separated list of Kubernetes annotation keys that will be used in the resource's labels metric."
    labels_allowed      = "(Optional) Specifies a Comma-separated list of additional Kubernetes label keys that will be used in the resource's labels metric."
  })
EOT
}

variable "network_policy" {
  type        = string
  default     = "cilium"
  description = "(Optional) Sets up network policy to be used with Azure CNI. Network policy allows us to control the traffic flow between pods. Currently supported values are `calico` and `cilium`. Defaults to `cilium`."
  nullable    = false

  validation {
    condition     = can(regex("^(calico|cilium)$", var.network_policy))
    error_message = "network_policy must be either calico or cilium."
  }
}

variable "node_labels" {
  type        = map(string)
  default     = {}
  description = "(Optional) A map of Kubernetes labels which should be applied to nodes in this Node Pool."
}

variable "node_pools" {
  type = map(object({
    name                 = string
    vm_size              = string
    orchestrator_version = string
    # do not add nodecount because we enforce the use of auto-scaling
    max_count       = optional(number)
    min_count       = optional(number)
    os_sku          = optional(string, "AzureLinux")
    os_disk_type    = optional(string, "Managed")
    mode            = optional(string)
    os_disk_size_gb = optional(number, null)
    tags            = optional(map(string), {})
    labels          = optional(map(string), {})
  }))
  default     = {}
  description = <<-EOT
A map of node pools that need to be created and attached on the Kubernetes cluster. The key of the map can be the name of the node pool, and the key must be static string. The value of the map is a `node_pool` block as defined below:
map(object({
  name                 = (Required) The name of the Node Pool which should be created within the Kubernetes Cluster. Changing this forces a new resource to be created. A Windows Node Pool cannot have a `name` longer than 6 characters. A random suffix of 4 characters is always added to the name to avoid clashes during recreates.
  vm_size              = (Required) The SKU which should be used for the Virtual Machines used in this Node Pool. Changing this forces a new resource to be created.
  orchestrator_version = (Required) The version of Kubernetes which should be used for this Node Pool. Changing this forces a new resource to be created.
  max_count            = (Optional) The maximum number of nodes which should exist within this Node Pool. Valid values are between `0` and `1000` and must be greater than or equal to `min_count`.
  min_count            = (Optional) The minimum number of nodes which should exist within this Node Pool. Valid values are between `0` and `1000` and must be less than or equal to `max_count`.
  os_sku               = (Optional) Specifies the OS SKU used by the agent pool. Possible values include: `Ubuntu`or `AzureLinux`. If not specified, the default is `AzureLinux`. Changing this forces a new resource to be created.
  os_disk_type         = (Optional) Specifies the type of disk which should be used for the Operating System. Possible values include: `Managed`or `Ephemeral`. If not specified, the default is `Managed`. Changing this forces a new resource to be created.
  mode                 = (Optional) Should this Node Pool be used for System or User resources? Possible values are `System` and `User`. Defaults to `User`.
  os_disk_size_gb      = (Optional) The Agent Operating System disk size in GB. Changing this forces a new resource to be created.
  tags                 = (Optional) A mapping of tags to assign to the resource. At this time there's a bug in the AKS API where Tags for a Node Pool are not stored in the correct case - you [may wish to use Terraform's `ignore_changes` functionality to ignore changes to the casing](https://www.terraform.io/language/meta-arguments/lifecycle#ignore_changess) until this is fixed in the AKS API.
  labels               = (Optional) A map of Kubernetes labels which should be applied to nodes in this Node Pool.
}))

Example input:
```terraform
  node_pools = {
    workload = {
      name                 = "workload"
      vm_size              = "Standard_D2d_v5"
      orchestrator_version = "1.28"
      max_count            = 110
      min_count            = 2
      os_sku               = "Ubuntu"
      mode                 = "User"
    },
    ingress = {
      name                 = "ingress"
      vm_size              = "Standard_D2d_v5"
      orchestrator_version = "1.28"
      max_count            = 4
      min_count            = 2
      os_sku               = "Ubuntu"
      os_disk_type         = "Ephemeral"
      mode                 = "User"
    }
  }
  ```
EOT
  nullable    = false

  validation {
    condition     = alltrue([for pool in var.node_pools : contains(["Ubuntu", "AzureLinux"], pool.os_sku)])
    error_message = "os_sku must be either Ubuntu or AzureLinux"
  }
}

variable "orchestrator_version" {
  type        = string
  default     = null
  description = "Specify which Kubernetes release to use. Specify only minor version, such as '1.28'."
}

variable "os_disk_type" {
  type        = string
  default     = "Managed"
  description = "(Optional) Specifies the OS Disk Type used by the agent pool. Possible values include: `Managed` or `Ephemeral`. If not specified, the default is `Managed`.Changing this forces a new resource to be created."

  validation {
    condition     = can(regex("^(Managed|Ephemeral)$", var.os_disk_type))
    error_message = "os_disk_type must be either Managed or Ephemeral"
  }
}

variable "os_sku" {
  type        = string
  default     = "AzureLinux"
  description = "(Optional) Specifies the OS SKU used by the agent pool. Possible values include: `Ubuntu` or `AzureLinux`. If not specified, the default is `AzureLinux`.Changing this forces a new resource to be created."

  validation {
    condition     = can(regex("^(Ubuntu|AzureLinux)$", var.os_sku))
    error_message = "os_sku must be either Ubuntu or AzureLinux"
  }
}

variable "outbound_type" {
  type        = string
  default     = "loadBalancer"
  description = "(Optional) Specifies the outbound type that will be used for cluster outbound (egress) routing. Possible values include: `loadBalancer`,`userDefinedRouting`,`managedNATGateway`,`userAssignedNATGateway`. If not specified, the default is `loadBalancer`.Changing this forces a new resource to be created."

  validation {
    condition     = can(regex("^(loadBalancer|userDefinedRouting|managedNATGateway|userAssignedNATGateway)$", var.outbound_type))
    error_message = "outbound_type must be  loadBalancer, userDefinedRouting, managedNATGateway, userAssignedNATGateway"
  }
}

variable "private_dns_zone_id" {
  type        = string
  default     = null
  description = "(Optional) Either the ID of Private DNS Zone which should be delegated to this Cluster."

  validation {
    condition     = var.private_dns_zone_id == null || can(regex("^(/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft.Network/privateDnsZones/[^/]+)$", var.private_dns_zone_id))
    error_message = "private_dns_zone_id must be a valid Private DNS Zone ID"
  }
}

variable "private_dns_zone_id_enabled" {
  type        = bool
  default     = false
  description = "(Optional) Enable private DNS zone integration for the AKS cluster."
  nullable    = false
}

variable "rbac_aad_admin_group_object_ids" {
  type        = list(string)
  default     = null
  description = "Object ID of groups with admin access."
}

variable "rbac_aad_azure_rbac_enabled" {
  type        = bool
  default     = null
  description = "(Optional) Is Role Based Access Control based on Azure AD enabled?"
}

variable "rbac_aad_tenant_id" {
  type        = string
  default     = null
  description = "(Optional) The Tenant ID used for Azure Active Directory Application. If this isn't specified the Tenant ID of the current Subscription is used."
}

# tflint-ignore: terraform_unused_declarations
variable "tags" {
  type        = map(string)
  default     = null
  description = "(Optional) Tags of the resource."
}
