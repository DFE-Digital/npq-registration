module API
  class BaseController < ActionController::API
    before_action :set_cache_headers
    before_action :remove_charset
    before_action :check_filter_is_valid, if: -> { params[:filter].present? }

    include API::TokenAuthenticatable
    include ActionController::MimeResponds
    include API::LoggerPayload

    include DfE::Analytics::Requests

    rescue_from ActionController::UnpermittedParameters, with: :unpermitted_parameter_response
    rescue_from ActionController::BadRequest, with: :bad_request_response
    rescue_from ArgumentError, with: :bad_request_response
    rescue_from API::Errors::FilterValidationError, with: :filter_validation_error_response

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

    def api_token_scope
      APIToken.scopes[:lead_provider]
    end

    def set_cache_headers
      no_store
    end

    def check_participant_id_change
      return unless (participant_id_change = ParticipantIdChange.find_by(from_participant_id: params[:ecf_id]))

      errors = [{
        title: "Participant ID has been changed",
        detail: I18n.t("participant_id.changed", **participant_id_change.i18n_params),
        participant_id_changes: [API::ParticipantIdChangeSerializer.render_as_hash(participant_id_change)],
      }]

      render json: { errors: }, status: :gone
    end

    def check_filter_is_valid
      raise ActionController::BadRequest, I18n.t(:invalid_filter) unless params[:filter].is_a?(ActionController::Parameters)
    end
  end
end
