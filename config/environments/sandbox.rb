require Rails.root.join("config/environments/production")

Rails.application.configure do
  config.log_level = :info

  config.x.teacher_auth.enabled = false
end
