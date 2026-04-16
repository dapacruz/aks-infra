output "aks_resource_group_name" {
  value = azurerm_resource_group.aks.name
}

output "aks_cluster_name" {
  value = azurerm_kubernetes_cluster.main.name
}

output "aks_kv_secrets_provider_app_id" {
  value = azurerm_kubernetes_cluster.main.key_vault_secrets_provider[0].secret_identity[0].client_id
}

output "traefik_ip" {
  value = azurerm_public_ip.traefik.ip_address
}

output "cloudflare_dns_records" {
  value = module.customer1.dns_record_names
}

output "grafana_dns_record" {
  description = "Hostname of the Grafana DNS record."
  value       = cloudflare_dns_record.grafana.name
}

output "grafana_user" {
  value = var.GRAFANA_USER
}

output "grafana_password" {
  value = var.GRAFANA_PASSWORD
}

