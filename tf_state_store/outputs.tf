output "storage_account_name" {
  value = azurerm_storage_account.main.name
}

output "container_name" {
  value = azurerm_storage_container.main.name
}

output "sp_role_name" {
  value = azurerm_role_definition.main.name
}

output "tenant_id" {
  value = data.azurerm_client_config.current.tenant_id
}

output "subscription_id" {
  value = data.azurerm_subscription.current.subscription_id
}

output "client_id" {
  value = azuread_service_principal.main.client_id
}

output "client_secret" {
  value = nonsensitive(azuread_service_principal_password.main.value)
}

