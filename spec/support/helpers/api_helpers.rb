module Helpers
  module APIHelpers
    def api_get(url, params: {}, headers: {}, token: nil)
      token ||= lead_provider_token
      headers ||= {}
      headers["Authorization"] = "Bearer #{token}"

      get url, params:, headers:
    end

    def api_post(url, params: {}, headers: {}, token: nil)
      token ||= lead_provider_token
      headers ||= {}
      headers["Authorization"] = "Bearer #{token}"
      headers["Content-Type"] = "application/json"

      post url, params:, headers:
    end

    def api_put(url, params: {}, headers: {}, token: nil)
      token ||= lead_provider_token
      headers ||= {}
      headers["Authorization"] = "Bearer #{token}"
      headers["Content-Type"] = "application/json"

      put url, params:, headers:
    end

    def parsed_response
      Oj.load(response.body)
    end

    def response_ids
      parsed_response["data"].map { |data| data["id"] }
    end

    def lead_provider_token
      lead_provider = current_lead_provider if defined?(current_lead_provider)
      lead_provider ||= FactoryBot.create(:lead_provider)

      APIToken.create_with_random_token!(lead_provider:)
    end
  end
end
