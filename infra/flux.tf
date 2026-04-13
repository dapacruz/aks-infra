resource "azurerm_kubernetes_cluster_extension" "flux" {
  name           = "orion-flux"
  cluster_id     = azurerm_kubernetes_cluster.main.id
  extension_type = "microsoft.flux"

  depends_on = [azurerm_kubernetes_cluster_node_pool.user]
}

resource "azurerm_kubernetes_flux_configuration" "main" {
  name       = "orion-staging"
  cluster_id = azurerm_kubernetes_cluster.main.id
  namespace  = "flux-system"

  git_repository {
    url             = "https://github.com/dapacruz/orion-gitops"
    reference_type  = "branch"
    reference_value = "main"
  }

  kustomizations {
    name                       = "flux-system"
    path                       = "./flux-system"
    sync_interval_in_seconds   = 300
    garbage_collection_enabled = true
  }

  scope = "cluster"

  depends_on = [azurerm_kubernetes_cluster_extension.flux]
}

resource "kubernetes_config_map_v1" "flux_cluster_vars" {
  metadata {
    name      = "cluster-vars"
    namespace = "flux-system"
  }

  data = {
    AKS_KEYVAULT_IDENTITY_CLIENT_ID = azurerm_kubernetes_cluster.main.key_vault_secrets_provider[0].secret_identity[0].client_id
    AZURE_TENANT_ID                 = data.azurerm_client_config.current.tenant_id
    TRAEFIK_IP                      = azurerm_public_ip.traefik.ip_address
  }

  depends_on = [azurerm_kubernetes_cluster_extension.flux]
}

