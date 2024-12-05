# # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 5. Outputs
# # # # # # # # # # # # # # # # # # # # # # # # # # # # #

output "resource_group_name" {
  value = azurerm_resource_group.lab_environment.name
}

output "display" {
  value = format(
    "Done! Resources are available in %s. Access here: https://portal.azure.com/#@%s/resource%s",
    azurerm_resource_group.lab_environment.name,
    data.azurerm_client_config.current.tenant_id,
    azurerm_resource_group.lab_environment.id
  )
}