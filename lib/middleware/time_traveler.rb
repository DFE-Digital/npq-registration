require "active_support/testing/time_helpers"

module Middleware
  class TimeTraveler
    include ActiveSupport::Testing::TimeHelpers

    def initialize(app)
      @app = app
    end

    def call(env)
      return @app.call(env) unless env.key?("HTTP_X_WITH_SERVER_DATE") && !Rails.env.production?

      travel_to(Time.zone.parse(env["HTTP_X_WITH_SERVER_DATE"])) do
        @app.call(env)
      end
    end
  end
end
