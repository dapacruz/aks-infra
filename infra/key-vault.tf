resource "azurerm_key_vault" "orion_vault" {
  name                = "kv-orion-staging-Cv1N"
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  soft_delete_retention_days = 7
  purge_protection_enabled   = false

  rbac_authorization_enabled = true
  depends_on                = [azurerm_kubernetes_cluster.main]
}

resource "azurerm_role_assignment" "kv_admin" {
  scope                = azurerm_key_vault.orion_vault.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_role_assignment" "aks_keyvault_secrets_provider" {
  scope                = azurerm_key_vault.orion_vault.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_kubernetes_cluster.main.key_vault_secrets_provider[0].secret_identity[0].object_id
}

resource "azurerm_key_vault_secret" "grafana_admin_user" {
  name         = "grafana-admin-user"
  value        = var.GRAFANA_USER
  key_vault_id = azurerm_key_vault.orion_vault.id

  depends_on = [azurerm_role_assignment.kv_admin]
}

resource "azurerm_key_vault_secret" "grafana_admin_password" {
  name         = "grafana-admin-password"
  value        = var.GRAFANA_PASSWORD
  key_vault_id = azurerm_key_vault.orion_vault.id

  depends_on = [azurerm_role_assignment.kv_admin]
}

resource "azurerm_key_vault_secret" "grafana_telegram_bot_token" {
  name         = "grafana-telegram-bot-token"
  value        = var.GRAFANA_TELEGRAM_BOT_TOKEN
  key_vault_id = azurerm_key_vault.orion_vault.id

  lifecycle {
    ignore_changes = [value]
  }

  depends_on = [azurerm_role_assignment.kv_admin]
}

resource "azurerm_key_vault_secret" "grafana_telegram_chat_id" {
  name         = "grafana-telegram-chat-id"
  value        = var.GRAFANA_TELEGRAM_CHAT_ID
  key_vault_id = azurerm_key_vault.orion_vault.id

  lifecycle {
    ignore_changes = [value]
  }

  depends_on = [azurerm_role_assignment.kv_admin]
}

