module TeacherAuth
  class RefreshAccessToken
    include HTTParty

    default_timeout 15.seconds
    raise_on 400..599

    def self.call(refresh_token:)
      new(refresh_token:).call
    end

    def initialize(refresh_token:)
      @refresh_token = refresh_token
    end

    def call
      response = self.class.post(
        "#{Rails.configuration.x.teacher_auth.domain.to_s.chomp('/')}/oauth2/token",
        body: {
          grant_type: "refresh_token",
          refresh_token: @refresh_token,
          client_id: Rails.configuration.x.teacher_auth.client_id,
          client_secret: Rails.configuration.x.teacher_auth.client_secret,
        },
        headers: { "Content-Type" => "application/x-www-form-urlencoded" },
      )

      response.parsed_response["refresh_token"]
    end
  end
end
