# Storage container for backups
resource "azurerm_storage_container" "customer1" {
  name                  = "customer1"
  storage_account_id    = azurerm_storage_account.cnpg_backups.id
  container_access_type = "private"
}

data "azurerm_storage_account_blob_container_sas" "customer1" {
  connection_string = azurerm_storage_account.cnpg_backups.primary_connection_string
  container_name    = azurerm_storage_container.customer1.name
  https_only        = true

  start  = timestamp()
  expiry = timeadd(timestamp(), "17520h") # 2 years

  permissions {
    read   = true
    write  = true
    delete = true
    list   = true
    add    = true
    create = true
  }
}

resource "random_password" "customer1_db_password" {
  length  = 24
  special = false

  lifecycle {
    ignore_changes = all
  }
}

# Key Vault secrets
resource "azurerm_key_vault_secret" "storage_account_name" {
  name         = "storage-account-name"
  value        = azurerm_storage_account.cnpg_backups.name
  key_vault_id = azurerm_key_vault.orion_vault.id

  depends_on = [azurerm_role_assignment.kv_admin]
}

resource "azurerm_key_vault_secret" "customer1_blob_sas" {
  name         = "customer1-blob-sas"
  value        = data.azurerm_storage_account_blob_container_sas.customer1.sas
  key_vault_id = azurerm_key_vault.orion_vault.id

  depends_on = [azurerm_role_assignment.kv_admin]
}

resource "azurerm_key_vault_secret" "customer1_db_user" {
  name         = "customer1-db-user"
  value        = "app"
  key_vault_id = azurerm_key_vault.orion_vault.id

  depends_on = [azurerm_role_assignment.kv_admin]
}

resource "azurerm_key_vault_secret" "customer1_db_password" {
  name         = "customer1-db-password"
  value        = random_password.customer1_db_password.result
  key_vault_id = azurerm_key_vault.orion_vault.id

  depends_on = [azurerm_role_assignment.kv_admin]
}

# Create DNS records
locals {
  dns_records = {
    "customer1" = { name = "customer1.dcinfrastructures.io", proxied = true }
    "grafana" = { name = "grafana.dcinfrastructures.io", proxied = true }
  }
}

resource "cloudflare_dns_record" "aks_dns" {
  for_each = local.dns_records

  zone_id = var.CLOUDFLARE_ZONE_ID
  name    = each.value.name
  content   = azurerm_public_ip.traefik.ip_address
  type    = "A"
  ttl     = 1
  proxied = each.value.proxied
}

