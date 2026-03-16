output "cosmosdb_account_id" {
  description = "The ID of the Cosmos DB account."
  value       = azurerm_cosmosdb_account.this.id
}

output "cosmosdb_account_name" {
  description = "The name of the Cosmos DB account."
  value       = azurerm_cosmosdb_account.this.name
}

output "cosmosdb_account_endpoint" {
  description = "The endpoint of the Cosmos DB account."
  value       = azurerm_cosmosdb_account.this.endpoint
}

output "cosmosdb_account_read_endpoints" {
  description = "The read endpoints of the Cosmos DB account."
  value       = azurerm_cosmosdb_account.this.read_endpoints
}

output "cosmosdb_account_write_endpoints" {
  description = "The write endpoints of the Cosmos DB account."
  value       = azurerm_cosmosdb_account.this.write_endpoints
}

output "cosmosdb_account_primary_key" {
  description = "The primary key of the Cosmos DB account."
  value       = azurerm_cosmosdb_account.this.primary_key
  sensitive   = true
}

output "cosmosdb_account_secondary_key" {
  description = "The secondary key of the Cosmos DB account."
  value       = azurerm_cosmosdb_account.this.secondary_key
  sensitive   = true
}

output "cosmosdb_account_primary_readonly_key" {
  description = "The primary read-only key of the Cosmos DB account."
  value       = azurerm_cosmosdb_account.this.primary_readonly_key
  sensitive   = true
}

output "cosmosdb_account_connection_strings" {
  description = "The connection strings of the Cosmos DB account."
  value       = azurerm_cosmosdb_account.this.connection_strings
  sensitive   = true
}

output "sql_database_ids" {
  description = "Map of SQL database names to their IDs."
  value = {
    for key, db in azurerm_cosmosdb_sql_database.this : key => db.id
  }
}

output "sql_container_ids" {
  description = "Map of SQL container keys to their IDs."
  value = {
    for key, container in azurerm_cosmosdb_sql_container.this : key => container.id
  }
}

output "mongodb_database_ids" {
  description = "Map of MongoDB database names to their IDs."
  value = {
    for key, db in azurerm_cosmosdb_mongo_database.this : key => db.id
  }
}

output "mongodb_collection_ids" {
  description = "Map of MongoDB collection keys to their IDs."
  value = {
    for key, collection in azurerm_cosmosdb_mongo_collection.this : key => collection.id
  }
}

output "private_endpoint_id" {
  description = "The ID of the private endpoint."
  value       = try(azurerm_private_endpoint.this[0].id, null)
}

output "private_endpoint_ip_address" {
  description = "The private IP address of the private endpoint."
  value       = try(azurerm_private_endpoint.this[0].private_service_connection[0].private_ip_address, null)
}
