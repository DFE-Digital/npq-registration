require Rails.root.join("config/environments/production")

Rails.application.configure do
  config.log_level = :info
  config.ssl_options = { redirect: { exclude: ->(request) { request.path.include?("/healthcheck") } } }
  config.cache_store = :null_store
end
