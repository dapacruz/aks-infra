# Update the infra backend file
resource "null_resource" "update_backend_config" {
  triggers = {
    storage_account_name = azurerm_storage_account.main.name
    container_name       = azurerm_storage_container.main.name
    tenant_id            = data.azurerm_client_config.current.tenant_id
    subscription_id      = data.azurerm_subscription.current.subscription_id
    client_id            = azuread_service_principal.main.client_id
    client_secret        = nonsensitive(azuread_service_principal_password.main.value)
  }

  provisioner "local-exec" {
    environment = {
      STORAGE_ACCOUNT_NAME = azurerm_storage_account.main.name
      CONTAINER_NAME       = azurerm_storage_container.main.name
      TENANT_ID            = data.azurerm_client_config.current.tenant_id
      SUBSCRIPTION_ID      = data.azurerm_subscription.current.subscription_id
      CLIENT_ID            = azuread_service_principal.main.client_id
      CLIENT_SECRET        = nonsensitive(azuread_service_principal_password.main.value)
    }

    command = "bash ${path.module}/scripts/update-backend-config.sh"
  }
}

