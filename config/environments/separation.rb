require Rails.root.join("config/environments/production")

Rails.application.configure do
  config.log_level = :debug
  config.ssl_options = { redirect: { exclude: ->(request) { request.path.include?("/healthcheck") } } }

  # Enable/disable aspects of the NPQ separation
  config.npq_separation = {
    admin_portal_enabled: true,
    api_enabled: true,
    migration_enabled: false,
  }
end
