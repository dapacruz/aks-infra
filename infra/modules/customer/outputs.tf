output "storage_container_name" {
  description = "Name of the created storage container."
  value       = azurerm_storage_container.this.name
}

output "sas_token" {
  description = "Generated SAS token for the storage container."
  value       = data.azurerm_storage_account_blob_container_sas.this.sas
  sensitive   = true
}

output "db_password" {
  description = "Generated database password."
  value       = random_password.db_password.result
  sensitive   = true
}

output "dns_record_names" {
  description = "Map of DNS record keys to their hostnames."
  value        = { for k, rec in cloudflare_dns_record.this : k => rec.name }
}

