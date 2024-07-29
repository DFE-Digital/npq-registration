module External
  module EcfAPI
    class ConnectionWithAuthHeader < JsonApiClient::Connection
      def run(request_method, path, params: nil, headers: {}, body: nil)
        raise JsonApiClient::Errors::ServiceUnavailable.new(@env, "EcfAPI service unavailable") if Rails.application.config.npq_separation[:ecf_api_disabled]

        super(
          request_method,
          path,
          params:,
          headers: headers.update(
            "Authorization" => "Bearer #{ENV['ECF_APP_BEARER_TOKEN']}",
          ),
          body:
        )
      end
    end

    class RawParser
      def self.parse(_klass, response)
        response.body.presence || {}
      end
    end

    class Base < JsonApiClient::Resource
      self.site = "#{ENV['ECF_APP_BASE_URL']}/api/v1/"
      self.connection_class = ConnectionWithAuthHeader
    end
  end
end
