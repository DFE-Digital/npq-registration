variable "command" {
  type = list(string)
  default = []
}
variable "pull_request_number" {
  type    = string
  default = ""
}
variable "cluster" {
  description = "AKS cluster where this app is deployed. Either 'test' or 'production'"
}
variable "namespace" {
  description = "AKS namespace where this app is deployed"
}
variable "environment" {
  description = "Name of the deployed environment in AKS"
}
variable "azure_credentials_json" {
  default     = null
  description = "JSON containing the service principal authentication key when running in automation"
}
variable "azure_resource_prefix" {
  description = "Standard resource prefix. Usually s189t01 (test) or s189p01 (production)"
}

variable "azure_maintenance_window" {
  type = object({
    day_of_week  = number
    start_hour   = number
    start_minute = number
  })
  default = null
}
variable "config" {
  description = "Long name of the environment configuration, e.g. review, development, production..."
}
variable "config_short" {
  description = "Short name of the environment configuration, e.g. dv, st, pd..."
}
variable "service_name" {
  description = "Full name of the service. Lowercase and hyphen separated"
}
variable "service_short" {
  description = "Short name to identify the service. Up to 6 charcters."
}
variable "deploy_azure_backing_services" {
  default     = true
  description = "Deploy real Azure backing services like databases, as opposed to containers inside of AKS"
}
variable "deploy_snapshot_database" {
  type    = string
  default = false
}
variable "deploy_redis_cache" {
  type    = bool
  default = false
}
variable "enable_postgres_ssl" {
  default     = true
  description = "Enforce SSL connection from the client side"
}
variable "enable_postgres_backup_storage" {
  default     = false
  description = "Create a storage account to store database dumps"
}
variable "docker_image" {
  description = "Docker image full name to identify it in the registry. Includes docker registry, repository and tag e.g.: ghcr.io/dfe-digital/teacher-pay-calculator:673f6309fd0c907014f44d6732496ecd92a2bcd0"
}
variable "external_url" {
  default     = null
  description = "Healthcheck URL for StatusCake monitoring"
}
variable "statuscake_contact_groups" {
  default     = [291418,282453]
  description = "ID of the contact group in statuscake web UI"
}
variable "enable_monitoring" {
  default     = false
  description = "Enable monitoring and alerting"
}

variable "redis_cache_capacity" {
  default = 1
}

variable "redis_cache_family" {
  default = "C"
}

variable "redis_cache_sku_name" {
  default = "Standard"
}

variable "webapp_memory_max" {
  type    = string
  default = "1Gi"
}

variable "webapp_replicas" {
  type = number
  default = 1
}

variable "worker_memory_max" {
  type    = string
  default = "1Gi"
}

variable "worker_replicas" {
  type = number
  default = 1
}

variable "migration_worker_replicas" {
  type = number
  default = 0
}

variable "postgres_flexible_server_sku" {
  type = string
  default = "B_Standard_B1ms"
}

variable "postgres_snapshot_flexible_server_sku" {
  default = "B_Standard_B2ms"
}

variable "postgres_enable_high_availability" {
  type = bool
  default = false
}
variable "enable_logit" { default = false }
locals {
  environment_variables = yamldecode(file("${path.module}/config/${var.config}.yml"))

  azure_credentials = try(jsondecode(var.azure_credentials_json), null)
  access_domain          = "${var.service_name}-${var.environment}${var.pull_request_number}-web.${module.cluster_data.ingress_domain}"
  access_external_domain = try(local.environment_variables["ACCESS_EXTERNAL_DOMAIN"], local.access_domain)

  postgres_ssl_mode = var.enable_postgres_ssl ? "require" : "disable"
}
