require Rails.root.join("config/environments/production")

Rails.application.configure do
  config.log_level = :debug
  config.ssl_options = { redirect: { exclude: ->(request) { request.path.include?("/healthcheck") } } }

  config.cache_store = :redis_cache_store, { url: ENV["REDIS_CACHE_URL"] }

  # Enable/disable aspects of the NPQ separation
  config.npq_separation = {
    parity_check: {
      enabled: true,
      npq_url: "https://npq-registration-migration-web.teacherservices.cloud",
      ecf_url: "https://cpd-ecf-migration-web.teacherservices.cloud",
    },
  }
end
