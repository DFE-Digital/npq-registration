locals {
  environment  = "${var.environment}${var.pull_request_number}"
  service_name = "cpd-npq"
  domain       = var.environment == "review" ? "cpd-npq-${local.environment}-web.test.teacherservices.cloud" : module.web_application.hostname
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
  }
  secret_variables = {
    DATABASE_URL = module.postgres.url
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

  command       = ["bundle", "exec", "rake", "jobs:work"]
  probe_command = ["pgrep", "-f", "rake"]

  replicas   = var.worker_replicas
  max_memory = var.worker_memory_max
}
