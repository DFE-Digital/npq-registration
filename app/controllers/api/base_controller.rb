module API
  class BaseController < ActionController::API
    before_action :remove_charset

    include API::TokenAuthenticatable

    rescue_from ActionController::UnpermittedParameters, with: :unpermitted_parameter_response
    rescue_from ActionController::BadRequest, with: :bad_request_response
    rescue_from ArgumentError, with: :bad_request_response

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
  end
end
