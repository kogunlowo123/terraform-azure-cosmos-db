#--------------------------------------------------------------
# Azure Cosmos DB Account
#--------------------------------------------------------------
resource "azurerm_cosmosdb_account" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  offer_type          = var.offer_type
  kind                = var.kind

  enable_automatic_failover     = var.enable_automatic_failover
  enable_multiple_write_locations = var.enable_multi_region_writes
  enable_free_tier              = var.enable_free_tier
  ip_range_filter               = var.ip_range_filter

  consistency_policy {
    consistency_level       = var.consistency_policy.level
    max_interval_in_seconds = var.consistency_policy.level == "BoundedStaleness" ? var.consistency_policy.max_interval : null
    max_staleness_prefix    = var.consistency_policy.level == "BoundedStaleness" ? var.consistency_policy.max_staleness : null
  }

  dynamic "geo_location" {
    for_each = local.geo_locations
    content {
      location          = geo_location.value.location
      failover_priority = geo_location.value.failover_priority
      zone_redundant    = geo_location.value.zone_redundant
    }
  }

  dynamic "capabilities" {
    for_each = var.capabilities
    content {
      name = capabilities.value
    }
  }

  dynamic "virtual_network_rule" {
    for_each = var.virtual_network_rules
    content {
      id = virtual_network_rule.value
    }
  }

  dynamic "analytical_storage" {
    for_each = var.enable_analytical_storage ? [1] : []
    content {
      schema_type = "WellDefined"
    }
  }

  backup {
    type                = var.backup_type
    interval_in_minutes = var.backup_type == "Periodic" ? var.backup_interval : null
    retention_in_hours  = var.backup_type == "Periodic" ? var.backup_retention : null
  }

  dynamic "identity" {
    for_each = var.enable_cmk ? [1] : []
    content {
      type = "SystemAssigned"
    }
  }

  key_vault_key_id = var.enable_cmk ? var.key_vault_key_id : null

  tags = var.tags
}

#--------------------------------------------------------------
# SQL Databases
#--------------------------------------------------------------
resource "azurerm_cosmosdb_sql_database" "this" {
  for_each = var.sql_databases

  name                = each.key
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.this.name
  throughput          = each.value.max_throughput == null ? each.value.throughput : null

  dynamic "autoscale_settings" {
    for_each = each.value.max_throughput != null ? [1] : []
    content {
      max_throughput = each.value.max_throughput
    }
  }
}

#--------------------------------------------------------------
# SQL Containers
#--------------------------------------------------------------
resource "azurerm_cosmosdb_sql_container" "this" {
  for_each = local.sql_containers_map

  name                = each.value.container_key
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.this.name
  database_name       = azurerm_cosmosdb_sql_database.this[each.value.db_key].name

  partition_key_path    = each.value.partition_key_path
  partition_key_version = each.value.partition_key_version
  throughput            = each.value.max_throughput == null ? each.value.throughput : null
  default_ttl           = each.value.default_ttl
  analytical_storage_ttl = each.value.analytical_ttl

  dynamic "autoscale_settings" {
    for_each = each.value.max_throughput != null ? [1] : []
    content {
      max_throughput = each.value.max_throughput
    }
  }

  dynamic "unique_key" {
    for_each = each.value.unique_keys != null ? each.value.unique_keys : []
    content {
      paths = unique_key.value
    }
  }

  dynamic "indexing_policy" {
    for_each = each.value.indexing_policy != null ? [each.value.indexing_policy] : []
    content {
      indexing_mode = indexing_policy.value.indexing_mode

      dynamic "included_path" {
        for_each = indexing_policy.value.included_paths != null ? indexing_policy.value.included_paths : []
        content {
          path = included_path.value
        }
      }

      dynamic "excluded_path" {
        for_each = indexing_policy.value.excluded_paths != null ? indexing_policy.value.excluded_paths : []
        content {
          path = excluded_path.value
        }
      }
    }
  }
}

#--------------------------------------------------------------
# MongoDB Databases
#--------------------------------------------------------------
resource "azurerm_cosmosdb_mongo_database" "this" {
  for_each = var.mongodb_databases

  name                = each.key
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.this.name
  throughput          = each.value.max_throughput == null ? each.value.throughput : null

  dynamic "autoscale_settings" {
    for_each = each.value.max_throughput != null ? [1] : []
    content {
      max_throughput = each.value.max_throughput
    }
  }
}

#--------------------------------------------------------------
# MongoDB Collections
#--------------------------------------------------------------
resource "azurerm_cosmosdb_mongo_collection" "this" {
  for_each = local.mongo_collections_map

  name                = each.value.collection_key
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.this.name
  database_name       = azurerm_cosmosdb_mongo_database.this[each.value.db_key].name

  shard_key          = each.value.shard_key
  throughput         = each.value.max_throughput == null ? each.value.throughput : null
  default_ttl_seconds = each.value.default_ttl
  analytical_storage_ttl = each.value.analytical_ttl

  dynamic "autoscale_settings" {
    for_each = each.value.max_throughput != null ? [1] : []
    content {
      max_throughput = each.value.max_throughput
    }
  }

  dynamic "index" {
    for_each = each.value.indexes != null ? each.value.indexes : []
    content {
      keys   = index.value.keys
      unique = index.value.unique
    }
  }

  # Default _id index required by MongoDB API
  index {
    keys   = ["_id"]
    unique = true
  }
}

#--------------------------------------------------------------
# Private Endpoint
#--------------------------------------------------------------
resource "azurerm_private_endpoint" "this" {
  count = var.enable_private_endpoint && var.private_endpoint_subnet_id != null ? 1 : 0

  name                = local.private_endpoint_name
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = local.private_service_connection_name
    private_connection_resource_id = azurerm_cosmosdb_account.this.id
    is_manual_connection           = false
    subresource_names              = var.kind == "MongoDB" ? ["MongoDB"] : ["Sql"]
  }

  dynamic "private_dns_zone_group" {
    for_each = var.private_dns_zone_id != null ? [1] : []
    content {
      name                 = local.private_dns_zone_group_name
      private_dns_zone_ids = [var.private_dns_zone_id]
    }
  }

  tags = var.tags
}

#--------------------------------------------------------------
# Diagnostic Setting
#--------------------------------------------------------------
resource "azurerm_monitor_diagnostic_setting" "this" {
  count = 0 # Enable by providing a log_analytics_workspace_id variable

  name               = local.diagnostic_setting_name
  target_resource_id = azurerm_cosmosdb_account.this.id

  enabled_log {
    category = "DataPlaneRequests"
  }

  enabled_log {
    category = "QueryRuntimeStatistics"
  }

  enabled_log {
    category = "PartitionKeyStatistics"
  }

  enabled_log {
    category = "PartitionKeyRUConsumption"
  }

  metric {
    category = "Requests"
    enabled  = true
  }
}
