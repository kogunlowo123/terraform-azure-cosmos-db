resource "azurerm_resource_group" "test" {
  name     = "rg-cosmosdb-test"
  location = "eastus2"
}

module "test" {
  source = "../"

  name                = "cosmos-test-account"
  resource_group_name = azurerm_resource_group.test.name
  location            = azurerm_resource_group.test.location

  kind       = "GlobalDocumentDB"
  offer_type = "Standard"

  consistency_policy = {
    level = "Session"
  }

  geo_locations = [
    {
      location          = "eastus2"
      failover_priority = 0
      zone_redundant    = true
    }
  ]

  enable_automatic_failover = true
  enable_private_endpoint   = false

  sql_databases = {
    appdb = {
      containers = {
        users = {
          partition_key_path = "/userId"
        }
        orders = {
          partition_key_path = "/orderId"
          default_ttl        = 2592000
        }
      }
    }
  }

  tags = {
    Environment = "test"
    ManagedBy   = "terraform"
  }
}
