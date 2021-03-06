module EcfApi
  class ConnectionWithAuthHeader < JsonApiClient::Connection
    def run(request_method, path, params: nil, headers: {}, body: nil)
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
