variable "ARM_SUBSCRIPTION_ID" {
  type      = string
  sensitive = true
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

