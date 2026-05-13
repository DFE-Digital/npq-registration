require Rails.root.join("config/environments/production")

Rails.application.configure do
  config.log_level = :info

  config.x.api.previous_names = true
  config.x.api.cohort_suffix = true
end
