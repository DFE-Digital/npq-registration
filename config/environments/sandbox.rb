require Rails.root.join("config/environments/production")

Rails.application.configure do
  config.log_level = :info
  config.x.disable_legacy_api = true
end
