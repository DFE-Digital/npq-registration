# frozen_string_literal: true

require "./app/jobs/application_job"
require "./app/jobs/stream_api_requests_to_big_query_job"

module Middleware
  class ApiRequestMiddleware
    REQUEST_HEADER_KEYS = %w[
      HTTP_VERSION
      HTTP_HOST
      HTTP_USER_AGENT
      HTTP_ACCEPT
      HTTP_ACCEPT_ENCODING
      HTTP_AUTHORIZATION
      HTTP_CONNECTION
      HTTP_CACHE_CONTROL
      QUERY_STRING
    ].freeze

    PROCESSABLE_CONTENT_TYPES = %w[application/json application/x-www-form-urlencoded].freeze

    MAX_REQUEST_BODY_SIZE = 1_048_576 # 1 MB

    def initialize(app)
      @app = app
    end

    def call(env)
      dup._call(env)
    end

    def _call(env)
      @request = Rack::Request.new(env)
      @status, @headers, @response = @app.call(env)

      begin
        if trace_request?
          StreamAPIRequestsToBigQueryJob.perform_later(request_data.stringify_keys, response_data.stringify_keys, @status, Time.zone.now.to_s)
        end
      rescue StandardError => e
        Rails.logger.warn e.message
        Sentry.capture_exception(e)
      end

      [@status, @headers, @response]
    end

  private

    def response_body
      return "" unless @status > 299

      body = @response.respond_to?(:body) ? @response.body : @response.join
      body = body.join if body.is_a?(Array)
      body
    end

    def response_data
      {
        headers: @headers,
        body: response_body,
      }
    end

    def request_data
      {
        path: @request.path,
        params: @request.params,
        body: request_body,
        headers: request_headers,
        method: @request.request_method,
      }
    end

    def request_body
      return "" if @request.body.nil?

      body = @request.body.dup.tap(&:rewind)
      content = body.read(MAX_REQUEST_BODY_SIZE + 1)
      return "" if content.nil?

      if content.bytesize > MAX_REQUEST_BODY_SIZE
        return "[truncated: body exceeded #{MAX_REQUEST_BODY_SIZE} bytes]"
      end

      content.force_encoding("utf-8")
    end

    def request_headers
      @request.env.slice(*REQUEST_HEADER_KEYS)
    end

    def trace_request?
      trace_request_enabled? && vendor_api_path? && processable_content_type?
    end

    def vendor_api_path?
      @request.path =~ /^\/api\/v\d+\/.*$/
    end

    def processable_content_type?
      content_type = @request.content_type
      return true if content_type.blank?

      PROCESSABLE_CONTENT_TYPES.any? { |type| content_type.start_with?(type) }
    end

    def trace_request_enabled?
      !!Rails.application.config.x.enable_api_request_middleware
    end
  end
end
