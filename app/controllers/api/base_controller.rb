module API
  class BaseController < ActionController::API
    before_action do
      Rack::MiniProfiler.authorize_request
    end

    before_action :remove_charset

    include API::TokenAuthenticatable
    include ActionController::MimeResponds
    include API::LoggerPayload

    rescue_from ActionController::UnpermittedParameters, with: :unpermitted_parameter_response
    rescue_from ActionController::BadRequest, with: :bad_request_response
    rescue_from ArgumentError, with: :bad_request_response
    rescue_from API::Errors::FilterValidationError, with: :filter_validation_error_response

    after_action :append_profiler_data_to_json

  private

    def append_profiler_data_to_json
      return unless request.format.json? && Rack::MiniProfiler.current

      body = response.body.present? ? JSON.parse(response.body) : {}
      body["profiler"] = Rack::MiniProfiler.current.page_struct
      response.body = body.to_json
    end

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
