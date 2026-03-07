provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "rg-cosmosdb-complete"
  location = "East US"
}

resource "azurerm_virtual_network" "example" {
  name                = "vnet-cosmosdb-complete"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_subnet" "example" {
  name                 = "snet-cosmosdb-pe"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_private_dns_zone" "sql" {
  name                = "privatelink.documents.azure.com"
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "sql" {
  name                  = "cosmosdb-sql-dns-link"
  resource_group_name   = azurerm_resource_group.example.name
  private_dns_zone_name = azurerm_private_dns_zone.sql.name
  virtual_network_id    = azurerm_virtual_network.example.id
}

#--------------------------------------------------------------
# SQL API Cosmos DB (NoSQL)
#--------------------------------------------------------------
module "cosmosdb_sql" {
  source = "../../"

  name                = "cosmos-complete-sql"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  kind                = "GlobalDocumentDB"

  enable_automatic_failover  = true
  enable_multi_region_writes = true
  enable_analytical_storage  = true

  consistency_policy = {
    level         = "BoundedStaleness"
    max_interval  = 10
    max_staleness = 200
  }

  geo_locations = [
    {
      location          = "East US"
      failover_priority = 0
      zone_redundant    = true
    },
    {
      location          = "West US"
      failover_priority = 1
      zone_redundant    = false
    },
    {
      location          = "West Europe"
      failover_priority = 2
      zone_redundant    = false
    }
  ]

  sql_databases = {
    "users" = {
      max_throughput = 4000
      containers = {
        "profiles" = {
          partition_key_path = "/userId"
          max_throughput     = 4000
          analytical_ttl     = -1
          default_ttl        = 86400
          unique_keys        = [["/email"], ["/username"]]
          indexing_policy = {
            indexing_mode  = "consistent"
            included_paths = ["/*"]
            excluded_paths = ["/\"_etag\"/?", "/largeField/?"]
          }
        }
        "sessions" = {
          partition_key_path = "/userId"
          throughput         = 400
          default_ttl        = 3600
        }
      }
    }
    "orders" = {
      throughput = 400
      containers = {
        "transactions" = {
          partition_key_path = "/orderId"
          throughput         = 400
        }
      }
    }
  }

  enable_private_endpoint    = true
  private_endpoint_subnet_id = azurerm_subnet.example.id
  private_dns_zone_id        = azurerm_private_dns_zone.sql.id

  backup_type       = "Periodic"
  backup_interval   = 120
  backup_retention  = 24

  tags = {
    Environment = "production"
    Project     = "cosmosdb-complete"
    ManagedBy   = "terraform"
  }
}

#--------------------------------------------------------------
# MongoDB API Cosmos DB
#--------------------------------------------------------------
resource "azurerm_private_dns_zone" "mongo" {
  name                = "privatelink.mongo.cosmos.azure.com"
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "mongo" {
  name                  = "cosmosdb-mongo-dns-link"
  resource_group_name   = azurerm_resource_group.example.name
  private_dns_zone_name = azurerm_private_dns_zone.mongo.name
  virtual_network_id    = azurerm_virtual_network.example.id
}

module "cosmosdb_mongo" {
  source = "../../"

  name                = "cosmos-complete-mongo"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  kind                = "MongoDB"

  capabilities = ["EnableMongo"]

  enable_automatic_failover = true

  consistency_policy = {
    level = "Session"
  }

  geo_locations = [
    {
      location          = "East US"
      failover_priority = 0
      zone_redundant    = false
    }
  ]

  mongodb_databases = {
    "app_data" = {
      max_throughput = 4000
      collections = {
        "events" = {
          shard_key      = "eventType"
          max_throughput  = 4000
          default_ttl    = 604800
          indexes = [
            {
              keys   = ["eventType", "timestamp"]
              unique = false
            },
            {
              keys   = ["correlationId"]
              unique = true
            }
          ]
        }
        "logs" = {
          shard_key   = "source"
          throughput  = 400
          default_ttl = 86400
        }
      }
    }
  }

  enable_private_endpoint    = true
  private_endpoint_subnet_id = azurerm_subnet.example.id
  private_dns_zone_id        = azurerm_private_dns_zone.mongo.id

  backup_type = "Continuous"

  tags = {
    Environment = "production"
    Project     = "cosmosdb-complete"
    ManagedBy   = "terraform"
  }
}

#--------------------------------------------------------------
# Outputs
#--------------------------------------------------------------
output "sql_cosmosdb_endpoint" {
  value = module.cosmosdb_sql.cosmosdb_account_endpoint
}

output "mongo_cosmosdb_endpoint" {
  value = module.cosmosdb_mongo.cosmosdb_account_endpoint
}

output "sql_database_ids" {
  value = module.cosmosdb_sql.sql_database_ids
}

output "mongo_database_ids" {
  value = module.cosmosdb_mongo.mongodb_database_ids
}
