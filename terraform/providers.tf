provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    api_management {
      purge_soft_delete_on_destroy = true
      recover_soft_deleted = true
    }
    cognitive_account {
      purge_soft_delete_on_destroy = true
    }
  }
}
