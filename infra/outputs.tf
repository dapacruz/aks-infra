output "aks_resource_group_name" {
  value = azurerm_resource_group.aks.name
}

output "aks_cluster_name" {
  value = azurerm_kubernetes_cluster.main.name
}

output "traefik_ip" {
  value = azurerm_public_ip.traefik.ip_address
}


