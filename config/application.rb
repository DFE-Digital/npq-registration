require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module NpqRegistration
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    config.exceptions_app = routes

    config.middleware.use Rack::Deflater

    # don't use AJAX/XHR to submit forms by default
    config.action_view.form_with_generates_remote_forms = false

    config.action_mailer.delivery_method = :notify
    config.action_mailer.notify_settings = {
      api_key: ENV["GOVUK_NOTIFY_API_KEY"]
    }

    # Used to handle HTTP_X_WITH_SERVER_DATE header for server side datetime overwrite
    require "middleware/time_traveler"
    config.middleware.use Middleware::TimeTraveler

    # Used to stream API requests to BigQuery
    require "middleware/api_request_middleware"
    config.middleware.use Middleware::ApiRequestMiddleware
  end
end
