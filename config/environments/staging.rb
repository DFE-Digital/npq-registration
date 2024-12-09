require Rails.root.join("config/environments/production")

Rails.application.configure do
  config.log_level = :debug
  config.ssl_options = { redirect: { exclude: ->(request) { request.path.include?("/healthcheck") } } }
  config.cache_store = :null_store

  # Enable/disable aspects of the NPQ separation
  config.npq_separation = {
    parity_check: {
      enabled: false,
    },
  }
end
