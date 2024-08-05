module API
  class BaseController < ActionController::API
    before_action :remove_charset

    include API::TokenAuthenticatable
    include ActionController::MimeResponds

    rescue_from ActionController::UnpermittedParameters, with: :unpermitted_parameter_response
    rescue_from ActionController::BadRequest, with: :bad_request_response
    rescue_from ArgumentError, with: :bad_request_response
    rescue_from API::Errors::FilterValidationError, with: :filter_validation_error_response

    def append_info_to_payload(payload)
      super
      payload[:current_user_class] = current_lead_provider&.class&.name
      payload[:current_user_id] = current_lead_provider&.id
      payload[:current_user_name] = current_lead_provider&.name

      payload[:request_headers] = request.env.slice(
        "CONTENT_TYPE",
        "GATEWAY_INTERFACE",
        "HTTP_ACCEPT",
        "HTTP_ACCEPT_ENCODING",
        "HTTP_AUTHORIZATION",
        "HTTP_CONNECTION",
        "HTTP_HOST",
        "HTTP_USER_AGENT",
        "HTTP_VERSION",
        "ORIGINAL_FULLPATH",
        "ORIGINAL_SCRIPT_NAME",
        "PATH_INFO",
        "QUERY_STRING",
        "REMOTE_ADDR",
        "REQUEST_METHOD",
        "REQUEST_PATH",
        "REQUEST_URI",
        "ROUTES_9080_SCRIPT_NAME",
        "SCRIPT_NAME",
        "SERVER_NAME",
        "SERVER_PORT",
        "SERVER_PROTOCOL",
        "SERVER_SOFTWARE",
        "puma.request_body_wait",
        "rack.after_reply",
        "rack.attack.called",
        "rack.attack.throttle_data",
        "rack.hijack?",
        "rack.multiprocess",
        "rack.multithread",
        "rack.request.query_hash",
        "rack.request.query_string",
        "rack.run_once",
        "rack.url_scheme",
        "rack.version",
      )
      payload[:request_body] = request.raw_post

      payload[:response_headers] = response.headers
      if response.status != 200
        payload[:response_body] = response.body
      end
    end

  private

    def remove_charset
      ActionDispatch::Response.default_charset = nil
    end

    def unpermitted_parameter_response(exception)
      render json: { errors: API::Errors::Response.new(error: I18n.t(:unpermitted_parameters), params: exception.params).call }, status: :unprocessable_entity
    end

    def bad_request_response(exception)
      Sentry.capture_exception(exception)
      render json: { errors: API::Errors::Response.new(error: I18n.t(:bad_request), params: exception.message).call }, status: :bad_request
    end

    def filter_validation_error_response(exception)
      render json: { errors: API::Errors::Response.new(error: I18n.t(:unpermitted_parameters), params: exception.message).call }, status: :unprocessable_entity
    end
  end
end
