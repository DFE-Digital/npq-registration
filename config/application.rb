require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
# require "action_mailbox/engine"
# require "action_text/engine"
require "action_view/railtie"
require "sprockets/railtie"
# require "action_cable/engine"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module NpqRegistration
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.2

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    # config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Don't generate system test files.
    config.generators.system_tests = nil

    # NPQ specific changes
    config.exceptions_app = routes

    config.middleware.use Rack::Deflater

    # don't use AJAX/XHR to submit forms by default
    config.action_view.form_with_generates_remote_forms = false

    config.action_mailer.delivery_method = :notify
    config.action_mailer.notify_settings = {
      api_key: ENV["GOVUK_NOTIFY_API_KEY"],
    }

    # Used to handle HTTP_X_WITH_SERVER_DATE header for server side datetime overwrite
    require "middleware/time_traveler"
    config.middleware.use Middleware::TimeTraveler

    # Used to stream API requests to BigQuery
    require "middleware/api_request_middleware"
    config.middleware.use Middleware::ApiRequestMiddleware
    config.x.enable_api_request_middleware = true

    require "middleware/restore_secure_headers_request_config"
    config.middleware.use Middleware::RestoreSecureHeadersRequestConfig

    config.x.tracking_pixels_enabled = ENV["TRACKING_PIXELS"].to_s == "true"
    config.x.google_analytics_id = ENV["GOOGLE_ANALYTICS_ID"].presence

    # Use active record session store in all environments for consistency
    config.session_store :active_record_store, key: "_npq_registration_session",
                                               secure: !Rails.env.local?,
                                               expire_after: 2.weeks

    config.x.disable_legacy_api = true
  end
end
