require Rails.root.join("config/environments/production")

Rails.application.configure do
  config.log_level = :debug
  config.ssl_options = { redirect: { exclude: ->(request) { request.path.include?("/healthcheck") } } }
end
