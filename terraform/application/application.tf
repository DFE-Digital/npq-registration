locals {
  environment  = "${var.environment}${var.pull_request_number}"
  service_name = "cpd-npq"
  domain       = var.environment == "review" ? "npq-registration-${local.environment}-web.test.teacherservices.cloud" : module.web_application.hostname
}

module "application_configuration" {
  source = "./vendor/modules/aks//aks/application_configuration"

  namespace              = var.namespace
  environment            = local.environment
  azure_resource_prefix  = var.azure_resource_prefix
  service_short          = var.service_short
  config_short           = var.config_short
  secret_key_vault_short = "app"

  # Delete for non rails apps
  is_rails_application = true

  config_variables = {
    ENVIRONMENT_NAME = var.environment
    PGSSLMODE        = local.postgres_ssl_mode
    RAILS_ENV        = var.environment
    DOMAIN           = local.domain
    HOSTING_DOMAIN   = "https://${local.access_external_domain}"

    AZURE_STORAGE_ACCOUNT_NAME = azurerm_storage_account.uploads.name
    AZURE_STORAGE_CONTAINER    = azurerm_storage_container.uploads.name
  }
  secret_variables = {
    DATABASE_URL = module.postgres.url
    REDIS_CACHE_URL = var.deploy_redis_cache ? module.redis-cache[0].url : ""

    AZURE_STORAGE_ACCESS_KEY   = azurerm_storage_account.uploads.primary_access_key
  }
}

module "web_application" {
  source = "./vendor/modules/aks//aks/application"

  is_web = true

  name = "web"
  web_port = 8080
  namespace    = var.namespace
  environment  = local.environment
  service_name = var.service_name

  cluster_configuration_map  = module.cluster_data.configuration_map
  kubernetes_config_map_name = module.application_configuration.kubernetes_config_map_name
  kubernetes_secret_name     = module.application_configuration.kubernetes_secret_name

  docker_image = var.docker_image
  command = var.command

  replicas   = var.webapp_replicas
  max_memory = var.webapp_memory_max

  enable_logit = var.enable_logit
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

  // depends_on = [module.postgres]
}
