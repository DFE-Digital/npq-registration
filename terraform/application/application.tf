locals {
  environment  = "${var.environment}${var.app_suffix}"
  service_name = "teacher-training-entitlement"
}

module "application_configuration" {
  source = "./vendor/modules/aks//aks/application_configuration"

  namespace              = var.namespace
  environment            = local.environment
  azure_resource_prefix  = var.azure_resource_prefix
  service_short          = var.service_short
  config_short           = var.config_short
  secret_key_vault_short = "app"
  config_variables_path  = "${path.module}/config/${var.config}.yml"

  # Delete for non rails apps
  is_rails_application = true

  config_variables = {
    ENVIRONMENT_NAME = var.environment
    PGSSLMODE        = local.postgres_ssl_mode
    RAILS_ENV        = var.environment
    AZURE_STORAGE_ACCOUNT_NAME = module.storage_account.name
    AZURE_STORAGE_CONTAINER    = "uploads"
  }
  secret_variables = {
    DATABASE_URL = module.postgres.url
    REDIS_CACHE_URL = var.deploy_redis_cache ? module.redis-cache.url : ""
    AZURE_STORAGE_ACCESS_KEY   = module.storage_account.primary_access_key
  }
}

module "web_application" {
  source = "./vendor/modules/aks//aks/application"

  is_web = true
  web_port = 8080
  namespace    = var.namespace
  environment  = local.environment
  service_name = var.service_name


  cluster_configuration_map  = module.cluster_data.configuration_map
  kubernetes_config_map_name = module.application_configuration.kubernetes_config_map_name
  kubernetes_secret_name     = module.application_configuration.kubernetes_secret_name

  docker_image = var.docker_image
  enable_logit = true
  command = var.command
  probe_path = "/up"

  send_traffic_to_maintenance_page = var.send_traffic_to_maintenance_page
}

module "worker_application" {
  source = "./vendor/modules/aks//aks/application"

  is_web = false

  name = "worker"
  namespace    = var.namespace
  environment  = local.environment
  service_name = var.service_name

  cluster_configuration_map  = module.cluster_data.configuration_map
  kubernetes_config_map_name = module.application_configuration.kubernetes_config_map_name
  kubernetes_secret_name     = module.application_configuration.kubernetes_secret_name

  docker_image = var.docker_image

  command       = ["/bin/sh", "-c", "bundle exec rake jobs:work"]
  probe_command = ["pgrep", "-f", "rake"]

  replicas   = var.worker_replicas
  max_memory = var.worker_memory_max

  enable_logit = var.enable_logit
  enable_gcp_wif = var.enable_dfe_analytics_federated_auth

  depends_on = [time_sleep.wait_15_seconds]
}

// Delayed::Job can take several seconds to shutdown but terraform thinks it has
// gone away as soon as the signal is sent. This means Delayed::Job errors out
// when it is still running but the postgres container is removed.
//
// Adding a 15 second delay before removing postgres for review apps solves this
resource "time_sleep" "wait_15_seconds" {
  count = var.deploy_azure_backing_services ? 0 : 1
  depends_on = [module.postgres]
  destroy_duration = "15s"
}
