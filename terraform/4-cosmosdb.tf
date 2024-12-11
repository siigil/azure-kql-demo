# # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 4. Cosmos DB
# Creates 2 Cosmos DB instances, 1 public and 1 private
# WARNING: Can take up to 5 minutes to create, and up to 20 minutes to delete!
# # # # # # # # # # # # # # # # # # # # # # # # # # # # #

resource "azurerm_cosmosdb_account" "db" {
  for_each            = local.cosmosdb_config
  name                = "${local.resource_prefix}-cosmosdb-${each.value.suffix}"
  location            = azurerm_resource_group.lab_environment.location
  resource_group_name = azurerm_resource_group.lab_environment.name
  offer_type          = "Standard"
  kind                = "MongoDB"

  public_network_access_enabled = each.value.public

  consistency_policy {
    consistency_level       = "BoundedStaleness"
    max_interval_in_seconds = 300
    max_staleness_prefix    = 100000
  }

  geo_location {
    location          = "eastus"
    failover_priority = 1
  }

  geo_location {
    location          = "westus"
    failover_priority = 0
  }
}