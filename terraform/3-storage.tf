# # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 3. Storage
# Creates 3 storage accounts with different exposure and network rules
# # # # # # # # # # # # # # # # # # # # # # # # # # # # #

resource "azurerm_storage_account" "lab_account_public" {
  for_each = local.storage_config_public
  # 24 character limit (including var names), so this is super shortened.
  name                     = "storage${each.value.s}${random_integer.int.result}"
  resource_group_name      = azurerm_resource_group.lab_environment.name
  location                 = azurerm_resource_group.lab_environment.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  public_network_access_enabled = true

}

resource "azurerm_storage_container" "lab_container_public" {
  for_each              = local.storage_config_public
  name                  = "${local.resource_prefix}-container-${each.value.s}"
  storage_account_name  = azurerm_storage_account.lab_account_public[each.key].name
  container_access_type = each.value.container_public
}

resource "azurerm_storage_account" "lab_account_restricted" {
  for_each = local.storage_config_restricted
  # 24 character limit (including var names), so this is super shortened.
  name                     = "storage${each.value.s}${random_integer.int.result}"
  resource_group_name      = azurerm_resource_group.lab_environment.name
  location                 = azurerm_resource_group.lab_environment.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  public_network_access_enabled = true

  # Allow user's IP in network rules
  network_rules {
    default_action = "Deny"
    ip_rules       = ["${chomp(data.http.icanhazip.body)}"]
  }

}

resource "azurerm_storage_container" "lab_container_restricted" {
  for_each              = local.storage_config_restricted
  name                  = "${local.resource_prefix}-container-${each.value.s}"
  storage_account_name  = azurerm_storage_account.lab_account_restricted[each.key].name
  container_access_type = each.value.container_public
}

resource "azurerm_storage_account" "lab_account_private" {
  for_each = local.storage_config_private
  # 24 character limit (including var names), so this is super shortened.
  name                     = "storage${each.value.s}${random_integer.int.result}"
  resource_group_name      = azurerm_resource_group.lab_environment.name
  location                 = azurerm_resource_group.lab_environment.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  public_network_access_enabled = false

}