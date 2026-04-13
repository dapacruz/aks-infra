variable "ARM_SUBSCRIPTION_ID" {
  type      = string
  sensitive = true
}

variable "CLOUDFLARE_API_TOKEN" {
  description = "Cloudflare API token with DNS edit permissions"
  type        = string
  sensitive   = true
}

variable "CLOUDFLARE_ZONE_ID" {
  description = "Cloudflare Zone ID for the target domain"
  type        = string
}

variable "GRAFANA_USER" {
  description = "Grafana admin user"
  type        = string
}


variable "GRAFANA_PASSWORD" {
  description = "Grafana admin password"
  type        = string
}

variable "GRAFANA_TELEGRAM_BOT_TOKEN" {
  description = "Telegram bot token"
  type        = string
}

variable "GRAFANA_TELEGRAM_CHAT_ID" {
  description = "Telegram chat ID"
  type        = string
}

