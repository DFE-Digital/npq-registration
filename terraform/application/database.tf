module "redis-cache" {
  source = "git::https://github.com/DFE-Digital/terraform-modules.git//aks/redis?ref=testing"

  namespace                 = var.namespace
  environment               = local.environment
  azure_resource_prefix     = var.azure_resource_prefix
  service_name              = local.service_name
  service_short             = var.service_short
  config_short              = var.config_short
  azure_capacity            = var.redis_cache_capacity
  azure_family              = var.redis_cache_family
  azure_sku_name            = var.redis_cache_sku_name
  name                      = "cache"
  azure_maxmemory_policy    = "allkeys-lru"
  azure_patch_schedule      = [{ "day_of_week" : "Sunday", "start_hour_utc" : 01 }]

  cluster_configuration_map = module.cluster_data.configuration_map

  use_azure                 = var.deploy_azure_backing_services
  azure_enable_monitoring   = var.enable_monitoring

  count                     = var.deploy_redis_cache ? 1 : 0
}

module "postgres" {
  source = "./vendor/modules/aks//aks/postgres"

  namespace                      = var.namespace
  environment                    = local.environment
  azure_resource_prefix          = var.azure_resource_prefix
  service_name                   = var.service_name
  service_short                  = var.service_short
  config_short                   = var.config_short
  cluster_configuration_map      = module.cluster_data.configuration_map
  use_azure                      = var.deploy_azure_backing_services
  azure_enable_monitoring        = var.enable_monitoring
  azure_enable_backup_storage    = var.enable_postgres_backup_storage
  server_version                 = "14"
  azure_extensions               = ["btree_gin", "citext", "plpgsql", "pg_trgm"]
  azure_enable_high_availability = var.postgres_enable_high_availability
  azure_sku_name                 = var.postgres_flexible_server_sku
  azure_maintenance_window       = var.azure_maintenance_window
}

module "postgres-snapshot" {
  source = "./vendor/modules/aks//aks/postgres"

  count                 = var.deploy_snapshot_database ? 1 : 0
  name                  = "snapshot"
  namespace             = var.namespace
  environment           = local.environment
  azure_resource_prefix = var.azure_resource_prefix
  service_name          = local.service_name
  service_short         = var.service_short
  config_short          = var.config_short

  cluster_configuration_map = module.cluster_data.configuration_map

  azure_sku_name                 = var.postgres_snapshot_flexible_server_sku
  use_azure                      = var.deploy_azure_backing_services
  azure_enable_high_availability = false
  azure_enable_backup_storage    = false
  azure_enable_monitoring        = false
  azure_extensions               = ["btree_gin", "citext", "plpgsql", "pg_trgm"]
}
