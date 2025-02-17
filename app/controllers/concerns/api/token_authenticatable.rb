module API
  module TokenAuthenticatable
    extend ActiveSupport::Concern
    include ActionController::HttpAuthentication::Token::ControllerMethods

    included do
      before_action :authenticate
    end

  private

    def authenticate
      authenticate_token || render_unauthorized
    end

    def authenticate_token
      authenticate_with_http_token do |unhashed_token|
        @current_api_token = APIToken.find_by_unhashed_token(unhashed_token, scope: api_token_scope).tap do |api_token|
          if api_token
            PaperTrail.request.whodunnit = "Lead provider #{api_token.lead_provider_id}"
            api_token.update!(last_used_at: Time.zone.now)
          end
        end
      end
    end

    def render_unauthorized
      render json: { error: I18n.t(:unauthorized) }.to_json, status: :unauthorized
    end

    def current_lead_provider
      @current_api_token&.lead_provider
    end
  end
end
