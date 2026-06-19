require Rails.root.join("config/environments/production")

Rails.application.configure do
  config.log_level = :debug

  config.x.api.previous_names = true
end
