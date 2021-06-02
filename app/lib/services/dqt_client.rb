require "net/http"

module Services
  class DqtClient
    attr_reader :trn

    def initialize(trn:)
      @trn = trn
    end

    def call
      request = Net::HTTP::Get.new(uri)
      request["Authorization"] = "Bearer #{config.bearer_token}"

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
        http.request(request)
      end

      if response.code == "404"
        nil
      else
        JSON.parse(response.body)["data"]["attributes"]
      end
    end

  private

    def config
      @config ||= OpenStruct.new(
        bearer_token: ENV["ECF_APP_BEARER_TOKEN"],
        endpoint: "#{ENV['ECF_APP_BASE_URL']}/api/v1/dqt-records",
      )
    end

    def uri
      @uri ||= URI("#{config.endpoint}/#{trn}")
    end
  end
end
