variable "customer_name" {
  description = "Short identifier for the customer (e.g. 'customer1'). Used in resource names and secret keys."
  type        = string
}

variable "db_user" {
  description = "Database username to store in Key Vault."
  type        = string
  default     = "app"
}

variable "storage_account_id" {
  description = "ID of the shared Azure Storage Account used for CNPG backups."
  type        = string
}

variable "storage_account_primary_connection_string" {
  description = "Primary connection string of the shared Storage Account."
  type        = string
  sensitive   = true
}

variable "key_vault_id" {
  description = "ID of the Azure Key Vault where secrets will be stored."
  type        = string
}

variable "kv_admin_role_assignment_id" {
  description = <<EOT
    ID of the Key Vault admin role assignment. Passed in so the module can
    express the same depends_on ordering without referencing an external resource directly.
  EOT
  type        = string
}

variable "sas_validity_hours" {
  description = "How long (in hours) the generated SAS token should be valid for."
  type        = number
  default     = 17520 # 2 years
}

variable "cloudflare_zone_id" {
  description = "Cloudflare Zone ID for DNS record creation."
  type        = string
}

variable "traefik_ip_address" {
  description = "Public IP address of the Traefik ingress controller."
  type        = string
}

variable "dns_records" {
  description = <<EOT
    Map of DNS records to create. Each entry specifies the full hostname and
    whether the record should be Cloudflare-proxied.
  EOT
  type = map(object({
    name    = string
    proxied = bool
  }))
  default = {}
}

