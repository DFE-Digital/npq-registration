require Rails.root.join("config/environments/production")

Rails.application.configure do
  config.ssl_options = { redirect: { exclude: ->(request) { request.path.include?("/healthcheck") } } }
  config.cache_store = :memory_store
end
