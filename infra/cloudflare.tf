resource "cloudflare_dns_record" "grafana" {
  zone_id = var.CLOUDFLARE_ZONE_ID
  name    = "grafana.orion-staging.dcinfrastructures.io"
  content = azurerm_public_ip.traefik.ip_address
  type    = "A"
  ttl     = 1
  proxied = false
}

