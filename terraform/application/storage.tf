module "storage_account" {
  source = "./vendor/modules/aks//aks/storage_account"

  name                        = ""
  environment                 = local.environment
  azure_resource_prefix       = var.azure_resource_prefix
  service_short               = var.service_short
  config_short                = var.config_short

  public_network_access_enabled     = true
  container_delete_retention_days   = var.container_delete_retention_days
  blob_delete_retention_days        = var.blob_delete_retention_days
  containers                        = [{ name = "uploads" }]
  infrastructure_encryption_enabled = true
  last_access_time_enabled          = true
  create_encryption_scope           = false
  blob_delete_after_days            = 0
}
