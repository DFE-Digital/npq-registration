require Rails.root.join("config/environments/production")

Rails.application.configure do
  config.log_level = :debug

  config.x.teacher_auth.enabled = false
end
