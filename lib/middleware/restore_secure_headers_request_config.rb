module Middleware
  class RestoreSecureHeadersRequestConfig
    include SecureHeaders

    def initialize(app)
      @app = app
    end

    def call(env)
      request = ActionDispatch::Request.new(env)
      # this env entry is normally set,
      # but when the page being rendered is via the exceptions_app (as set in config/application.rb)
      # then it is not set, so we need to set it here
      request.env[SecureHeaders::SECURE_HEADERS_CONFIG] ||= SecureHeaders.config_for(request)
      @app.call(env)
    end
  end
end
