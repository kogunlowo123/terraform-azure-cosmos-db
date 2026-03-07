locals {
  geo_locations = length(var.geo_locations) > 0 ? var.geo_locations : [
    {
      location          = var.location
      failover_priority = 0
      zone_redundant    = false
    }
  ]

  # Flatten SQL containers for resource creation
  sql_containers = flatten([
    for db_key, db in var.sql_databases : [
      for container_key, container in(db.containers != null ? db.containers : {}) : {
        db_key                = db_key
        container_key         = container_key
        partition_key_path    = container.partition_key_path
        partition_key_version = container.partition_key_version
        throughput            = container.throughput
        max_throughput        = container.max_throughput
        default_ttl           = container.default_ttl
        analytical_ttl        = container.analytical_ttl
        unique_keys           = container.unique_keys
        indexing_policy       = container.indexing_policy
      }
    ]
  ])

  sql_containers_map = {
    for container in local.sql_containers :
    "${container.db_key}-${container.container_key}" => container
  }

  # Flatten MongoDB collections for resource creation
  mongo_collections = flatten([
    for db_key, db in var.mongodb_databases : [
      for collection_key, collection in(db.collections != null ? db.collections : {}) : {
        db_key         = db_key
        collection_key = collection_key
        shard_key      = collection.shard_key
        throughput     = collection.throughput
        max_throughput = collection.max_throughput
        default_ttl    = collection.default_ttl
        analytical_ttl = collection.analytical_ttl
        indexes        = collection.indexes
      }
    ]
  ])

  mongo_collections_map = {
    for collection in local.mongo_collections :
    "${collection.db_key}-${collection.collection_key}" => collection
  }

  # Private endpoint service connection name
  private_endpoint_name              = "${var.name}-pe"
  private_service_connection_name    = "${var.name}-psc"
  private_dns_zone_group_name        = "${var.name}-dns-zone-group"

  # Diagnostic settings
  diagnostic_setting_name = "${var.name}-diag"
}
