# Shared storage account name in Key Vault
resource "azurerm_key_vault_secret" "storage_account_name" {
  name         = "storage-account-name"
  value        = azurerm_storage_account.cnpg_backups.name
  key_vault_id = azurerm_key_vault.orion_vault.id

  depends_on = [azurerm_role_assignment.kv_admin]
}

module "customer1" {
  source = "./modules/customer"

  customer_name                             = "customer1"
  storage_account_id                        = azurerm_storage_account.cnpg_backups.id
  storage_account_primary_connection_string = azurerm_storage_account.cnpg_backups.primary_connection_string
  key_vault_id                              = azurerm_key_vault.orion_vault.id
  kv_admin_role_assignment_id               = azurerm_role_assignment.kv_admin.id
  cloudflare_zone_id                        = var.CLOUDFLARE_ZONE_ID
  traefik_ip_address                        = azurerm_public_ip.traefik.ip_address

  dns_records = {
    "customer1" = { name = "customer1.orion-staging.dcinfrastructures.io", proxied = false }
  }
}

