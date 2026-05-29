module TeachingRecordSystem
  class RefreshTokens
    class << self
      def refresh!(refresh_token)
        new(refresh_token).refresh!
      end
    end

    def initialize(refresh_token)
      @refresh_token = refresh_token
    end

    def refresh!
      response.values_at("access_token", "refresh_token")
    end

    def access_token
      response["access_token"]
    end

    def refresh_token
      response["refresh_token"]
    end

  private

    def teacher_auth_api
      Faraday.new(url: config.domain) do |conn|
        conn.request :url_encoded
        conn.response :json
        conn.response :raise_error
        conn.response :logger, Rails.logger if Rails.env.local?
      end
    end

    def request_body
      {
        grant_type: "refresh_token",
        refresh_token: @refresh_token,
        client_id: config.client_id,
        client_secret: config.client_secret,
      }
    end

    def response
      @response ||= teacher_auth_api.post("oauth2/token", request_body).body
    end

    def config
      Rails.configuration.x.teacher_auth
    end
  end
end
