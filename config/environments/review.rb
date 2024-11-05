require Rails.root.join("config/environments/production")

Rails.application.configure do
  config.ssl_options = { redirect: { exclude: ->(request) { request.path.include?("/healthcheck") } } }

  # Enable/disable aspects of the NPQ separation
  config.npq_separation = {
    parity_check: {
      enabled: false,
    },
  }
end
