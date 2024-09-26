require Rails.root.join("config/environments/production")

Rails.application.configure do
  config.log_level = :info
  config.ssl_options = { redirect: { exclude: ->(request) { request.path.include?("/healthcheck") } } }

  # Enable/disable aspects of the NPQ separation
  config.npq_separation = {
    admin_portal_enabled: false,
    api_enabled: false,
    migration_enabled: false,
    ecf_api_disabled: false,
  }
end
