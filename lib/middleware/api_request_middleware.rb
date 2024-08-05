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

    def initialize(app)
      @app = app
    end

    def call(env)
      dup._call(env)
    end

    def _call(env)
      @request = Rack::Request.new(env)
      status, @headers, @response = @app.call(env)

      begin
        if trace_request?
          StreamApiRequestsToBigQueryJob.perform_later(request_data.stringify_keys, response_data.stringify_keys, status, Time.zone.now.to_s)
        end
      rescue StandardError => e
        Rails.logger.warn e.message
        Sentry.capture_exception(e)
      end

      [status, @headers, @response]
    end

  private

    def response_data
      body = @response.respond_to?(:body) ? @response.body : @response.join
      body = body.join if body.is_a?(Array)

      {
        headers: @headers,
        body:,
      }
    end

    def request_data
      {
        path: @request.path,
        params: @request.params,
        body: @request.body.read.dup.force_encoding("utf-8"),
        headers: request_headers,
        method: @request.request_method,
      }
    end

    def request_headers
      @request.env.slice(*REQUEST_HEADER_KEYS)
    end

    def trace_request?
      Rails.env.in?(%w[migration review separation staging production]) && vendor_api_path?
    end

    def vendor_api_path?
      @request.path =~ /^\/api\/v\d+\/.*$/
    end
  end
end
