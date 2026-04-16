terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
    random = {
      source = "hashicorp/random"
    }
    cloudflare = {
      source = "cloudflare/cloudflare"
    }
  }
}

# Storage container for backups
resource "azurerm_storage_container" "this" {
  name                  = var.customer_name
  storage_account_id    = var.storage_account_id
  container_access_type = "private"
}

data "azurerm_storage_account_blob_container_sas" "this" {
  connection_string = var.storage_account_primary_connection_string
  container_name    = azurerm_storage_container.this.name
  https_only        = true

  start  = timestamp()
  expiry = timeadd(timestamp(), "${var.sas_validity_hours}h")

  permissions {
    read   = true
    write  = true
    delete = true
    list   = true
    add    = true
    create = true
  }
}

resource "random_password" "db_password" {
  length  = 24
  special = false

  lifecycle {
    ignore_changes = all
  }
}

# Key Vault secrets
resource "azurerm_key_vault_secret" "blob_sas" {
  name         = "${var.customer_name}-blob-sas"
  value        = data.azurerm_storage_account_blob_container_sas.this.sas
  key_vault_id = var.key_vault_id

  depends_on = [var.kv_admin_role_assignment_id]
}

resource "azurerm_key_vault_secret" "db_user" {
  name         = "${var.customer_name}-db-user"
  value        = var.db_user
  key_vault_id = var.key_vault_id

  depends_on = [var.kv_admin_role_assignment_id]
}

resource "azurerm_key_vault_secret" "db_password" {
  name         = "${var.customer_name}-db-password"
  value        = random_password.db_password.result
  key_vault_id = var.key_vault_id

  depends_on = [var.kv_admin_role_assignment_id]
}

# DNS records
resource "cloudflare_dns_record" "this" {
  for_each = var.dns_records

  zone_id = var.cloudflare_zone_id
  name    = each.value.name
  content = var.traefik_ip_address
  type    = "A"
  ttl     = 1
  proxied = each.value.proxied
}

