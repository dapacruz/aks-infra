resource "random_string" "storage_suffix" {
  length  = 6
  special = false
  upper   = false
}

locals {
  storage_name = "orion${random_string.storage_suffix.result}"
}

resource "azurerm_resource_group" "main" {
  name     = local.storage_name
  location = "West US 2"
}

resource "azurerm_storage_account" "main" {
  name                = local.storage_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  account_tier                      = "Standard"
  account_kind                      = "StorageV2"
  account_replication_type          = "GRS"
  https_traffic_only_enabled        = true
  min_tls_version                   = "TLS1_2"
  shared_access_key_enabled         = false
  default_to_oauth_authentication   = true
  infrastructure_encryption_enabled = false

  blob_properties {
    versioning_enabled            = true
    change_feed_enabled           = true
    change_feed_retention_in_days = 90
    last_access_time_enabled      = true

    delete_retention_policy {
      days = 30
    }

    container_delete_retention_policy {
      days = 30
    }
  }

  sas_policy {
    expiration_period = "00.02:00:00"
    expiration_action = "Log"
  }

}

resource "azurerm_storage_container" "main" {
  name                  = "tfstate"
  storage_account_id  = azurerm_storage_account.main.id
  container_access_type = "private"
}

resource "azurerm_role_definition" "main" {
  name        = "${local.storage_name}-write-access"
  scope       = data.azurerm_subscription.current.id
  description = "Custom role definition allowing write access to the storage account ${azurerm_storage_account.main.name}."

  permissions {
    actions = [
      "Microsoft.Storage/storageAccounts/blobServices/containers/read",
      "Microsoft.Storage/storageAccounts/blobServices/generateUserDelegationKey/action"
    ]
    data_actions = [
      "Microsoft.Storage/storageAccounts/blobServices/containers/blobs/read",
      "Microsoft.Storage/storageAccounts/blobServices/containers/blobs/write",
      "Microsoft.Storage/storageAccounts/blobServices/containers/blobs/add/action"
    ]
  }

  assignable_scopes = [
    data.azurerm_subscription.current.id
  ]
}


# Create a service principal to assign role to
resource "azuread_application" "main" {
  display_name = local.storage_name
  owners       = [data.azuread_client_config.current.object_id]
}

resource "azuread_service_principal" "main" {
  client_id                    = azuread_application.main.client_id
  app_role_assignment_required = false
  owners                       = [data.azuread_client_config.current.object_id]
}

resource "azuread_service_principal_password" "main" {
  service_principal_id = azuread_service_principal.main.id
}

resource "azurerm_role_assignment" "main" {
  scope                = azurerm_storage_account.main.id
  role_definition_id = azurerm_role_definition.main.role_definition_resource_id
  principal_id         = azuread_service_principal.main.object_id

  condition = templatefile("${path.module}/condition.tpl", {
    container_name = azurerm_storage_container.main.name
    state_path     = "aks-infra"
  })

  condition_version                = "2.0"
  skip_service_principal_aad_check = true

  depends_on = [azurerm_role_definition.main]
}

resource "azurerm_role_assignment" "current_user_blob_access" {
  scope                = azurerm_storage_account.main.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = "70633b4d-738d-4cf5-9298-2308c86be097"
}

