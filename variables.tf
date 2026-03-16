variable "name" {
  description = "Name of the Cosmos DB account."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group for the Cosmos DB account."
  type        = string
}

variable "location" {
  description = "Azure region for the Cosmos DB account."
  type        = string
}

variable "offer_type" {
  description = "Offer type for the Cosmos DB account."
  type        = string
  default     = "Standard"
}

variable "kind" {
  description = "Kind of Cosmos DB account (GlobalDocumentDB or MongoDB)."
  type        = string
  default     = "GlobalDocumentDB"

  validation {
    condition     = contains(["GlobalDocumentDB", "MongoDB"], var.kind)
    error_message = "The kind must be either 'GlobalDocumentDB' or 'MongoDB'."
  }
}

variable "consistency_policy" {
  description = "Consistency policy for the Cosmos DB account."
  type = object({
    level         = string
    max_interval  = optional(number, 5)
    max_staleness = optional(number, 100)
  })
  default = {
    level         = "Session"
    max_interval  = 5
    max_staleness = 100
  }

  validation {
    condition     = contains(["BoundedStaleness", "Eventual", "Session", "Strong", "ConsistentPrefix"], var.consistency_policy.level)
    error_message = "The consistency level must be one of: BoundedStaleness, Eventual, Session, Strong, ConsistentPrefix."
  }
}

variable "geo_locations" {
  description = "List of geo-locations for the Cosmos DB account."
  type = list(object({
    location          = string
    failover_priority = number
    zone_redundant    = optional(bool, false)
  }))
  default = []
}

variable "enable_automatic_failover" {
  description = "Enable automatic failover for the Cosmos DB account."
  type        = bool
  default     = true
}

variable "enable_multi_region_writes" {
  description = "Enable multi-region writes for the Cosmos DB account."
  type        = bool
  default     = false
}

variable "capabilities" {
  description = "List of capabilities to enable on the Cosmos DB account."
  type        = list(string)
  default     = []
}

variable "virtual_network_rules" {
  description = "List of virtual network subnet IDs for the Cosmos DB account."
  type        = list(string)
  default     = []
}

variable "ip_range_filter" {
  description = "Comma-separated list of IP addresses or ranges allowed to access the account."
  type        = string
  default     = null
}

variable "enable_free_tier" {
  description = "Enable the free tier for the Cosmos DB account."
  type        = bool
  default     = false
}

variable "sql_databases" {
  description = "Map of SQL databases to create in the Cosmos DB account."
  type = map(object({
    throughput     = optional(number)
    max_throughput = optional(number)
    containers = optional(map(object({
      partition_key_path    = string
      partition_key_version = optional(number, 2)
      throughput            = optional(number)
      max_throughput        = optional(number)
      default_ttl           = optional(number)
      analytical_ttl        = optional(number)
      unique_keys           = optional(list(list(string)), [])
      indexing_policy = optional(object({
        indexing_mode  = optional(string, "consistent")
        included_paths = optional(list(string), ["/*"])
        excluded_paths = optional(list(string), ["/\"_etag\"/?"])
      }))
    })), {})
  }))
  default = {}
}

variable "mongodb_databases" {
  description = "Map of MongoDB databases to create in the Cosmos DB account."
  type = map(object({
    throughput     = optional(number)
    max_throughput = optional(number)
    collections = optional(map(object({
      shard_key      = string
      throughput     = optional(number)
      max_throughput = optional(number)
      default_ttl    = optional(number)
      analytical_ttl = optional(number)
      indexes = optional(list(object({
        keys   = list(string)
        unique = optional(bool, false)
      })), [])
    })), {})
  }))
  default = {}
}

variable "enable_analytical_storage" {
  description = "Enable analytical storage on the Cosmos DB account."
  type        = bool
  default     = false
}

variable "analytical_storage_ttl" {
  description = "Default analytical storage TTL in seconds (-1 for infinite)."
  type        = number
  default     = null
}

variable "backup_type" {
  description = "Backup type for the Cosmos DB account (Periodic or Continuous)."
  type        = string
  default     = "Periodic"

  validation {
    condition     = contains(["Periodic", "Continuous"], var.backup_type)
    error_message = "The backup type must be either 'Periodic' or 'Continuous'."
  }
}

variable "backup_interval" {
  description = "Interval in minutes between backups (Periodic backup type only)."
  type        = number
  default     = 240
}

variable "backup_retention" {
  description = "Retention in hours for each backup (Periodic backup type only)."
  type        = number
  default     = 8
}

variable "enable_cmk" {
  description = "Enable customer-managed key encryption."
  type        = bool
  default     = false
}

variable "key_vault_key_id" {
  description = "Key Vault key URI for customer-managed key encryption."
  type        = string
  default     = null
}

variable "enable_private_endpoint" {
  description = "Create a private endpoint for the Cosmos DB account."
  type        = bool
  default     = true
}

variable "private_endpoint_subnet_id" {
  description = "Subnet ID for the private endpoint."
  type        = string
  default     = null
}

variable "private_dns_zone_id" {
  description = "Private DNS zone ID for the private endpoint."
  type        = string
  default     = null
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID for diagnostic settings."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}
