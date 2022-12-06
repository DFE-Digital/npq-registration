Flipper::UI.configure do |config|
  # Add confirmation box when clicking "fully enable" feature
  config.confirm_fully_enable = true

  # Turn off the recommendation to set up Flipper CLoud
  config.cloud_recommendation = false

  # Disable Taylor Swift video when no features are available
  config.fun = false

  # Disable ability to delete feature flags from the UI
  config.feature_removal_enabled = false

  # Disable ability to add feature flags from the UI
  config.feature_creation_enabled = false

  # Add link back to admin interface to UI
  config.application_breadcrumb_href = "/admin"
end
