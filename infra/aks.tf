resource "azurerm_resource_group" "aks" {
  name     = "aks-infra"
  location = "West US 2"
}

# AKS Cluster
resource "azurerm_kubernetes_cluster" "main" {
  name                = "orion-staging"
  oidc_issuer_enabled = true
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name
  dns_prefix          = "staging"

  azure_active_directory_role_based_access_control {
    azure_rbac_enabled     = true
    admin_group_object_ids = ["70633b4d-738d-4cf5-9298-2308c86be097"]
  }

  # Automatic upgrades,  patch level only for stability
  automatic_upgrade_channel = "patch"

  # Node OS auto-upgrade for security patches
  node_os_upgrade_channel = "NodeImage"

  # System node pool for critical Kubernetes components
  # Tainted with CriticalAddonsOnly so user workloads don't schedule here
  default_node_pool {
    name                         = "agentpool"
    node_count                   = 2
    vm_size                      = "Standard_D2s_v3"
    only_critical_addons_enabled = true

    upgrade_settings {
      max_surge = "33%"
    }
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin     = "azure"
    network_policy     = "cilium"
    network_data_plane = "cilium"
  }

  key_vault_secrets_provider {
    secret_rotation_enabled = false
  }

  maintenance_window_auto_upgrade {
    frequency   = "Weekly"
    interval    = 1
    duration    = 4
    day_of_week = "Sunday"
    start_time  = "02:00"
    utc_offset  = "+00:00"
  }

  maintenance_window_node_os {
    frequency   = "Weekly"
    interval    = 1
    duration    = 4
    day_of_week = "Sunday"
    start_time  = "02:00"
    utc_offset  = "+00:00"
  }
}

# User node pool - for application workloads
resource "azurerm_kubernetes_cluster_node_pool" "user" {
  name                  = "userpool"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  vm_size               = "Standard_D2s_v3"
  node_count            = 2

  upgrade_settings {
    max_surge = "33%"
  }
}

resource "azurerm_public_ip" "traefik" {
  name                = "traefik-ingress"
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_kubernetes_cluster.main.node_resource_group
  allocation_method   = "Static"
  sku                 = "Standard"

  provisioner "local-exec" {
    when    = destroy
    command = "kubectl delete service -n traefik traefik-traefik --ignore-not-found"
  }
}

resource "azurerm_role_assignment" "aks_cluster_admin" {
  scope                = azurerm_kubernetes_cluster.main.id
  role_definition_name = "Azure Kubernetes Service Cluster Admin Role"
  principal_id         = "70633b4d-738d-4cf5-9298-2308c86be097"
}

