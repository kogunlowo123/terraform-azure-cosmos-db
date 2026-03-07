provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "rg-cosmosdb-basic"
  location = "East US"
}

module "cosmosdb" {
  source = "../../"

  name                = "cosmos-basic-example"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location

  enable_private_endpoint = false

  consistency_policy = {
    level = "Session"
  }

  sql_databases = {
    "mydb" = {
      throughput = 400
      containers = {
        "mycontainer" = {
          partition_key_path = "/id"
          throughput         = 400
        }
      }
    }
  }

  tags = {
    Environment = "dev"
    Project     = "cosmosdb-basic"
  }
}

output "cosmosdb_endpoint" {
  value = module.cosmosdb.cosmosdb_account_endpoint
}
