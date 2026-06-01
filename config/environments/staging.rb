require Rails.root.join("config/environments/production")

Rails.application.configure do
  config.log_level = :debug

  config.x.teacher_auth.enabled = true
  config.x.api.previous_names = true
  config.x.api.cohort_suffix = true
end
