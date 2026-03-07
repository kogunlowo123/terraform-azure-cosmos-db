provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "rg-cosmosdb-advanced"
  location = "East US"
}

resource "azurerm_virtual_network" "example" {
  name                = "vnet-cosmosdb"
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

resource "azurerm_private_dns_zone" "example" {
  name                = "privatelink.documents.azure.com"
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "example" {
  name                  = "cosmosdb-dns-link"
  resource_group_name   = azurerm_resource_group.example.name
  private_dns_zone_name = azurerm_private_dns_zone.example.name
  virtual_network_id    = azurerm_virtual_network.example.id
}

module "cosmosdb" {
  source = "../../"

  name                = "cosmos-advanced-example"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location

  enable_automatic_failover  = true
  enable_multi_region_writes = true

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
    }
  ]

  enable_analytical_storage = true

  sql_databases = {
    "orders" = {
      max_throughput = 4000
      containers = {
        "items" = {
          partition_key_path = "/category"
          max_throughput     = 4000
          analytical_ttl     = -1
          unique_keys        = [["/email"]]
          indexing_policy = {
            indexing_mode  = "consistent"
            included_paths = ["/*"]
            excluded_paths = ["/\"_etag\"/?"]
          }
        }
      }
    }
  }

  enable_private_endpoint    = true
  private_endpoint_subnet_id = azurerm_subnet.example.id
  private_dns_zone_id        = azurerm_private_dns_zone.example.id

  backup_type      = "Continuous"

  tags = {
    Environment = "staging"
    Project     = "cosmosdb-advanced"
  }
}

output "cosmosdb_endpoint" {
  value = module.cosmosdb.cosmosdb_account_endpoint
}

output "private_endpoint_ip" {
  value = module.cosmosdb.private_endpoint_ip_address
}
