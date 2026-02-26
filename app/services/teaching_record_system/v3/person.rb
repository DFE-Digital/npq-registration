module TeachingRecordSystem
  module V3
    class Person
      include HTTParty

      format :json
      base_uri ENV["TRS_API_URL"]
      default_timeout 5.seconds
      raise_on 400..599

      class << self
        def find_with_token(access_token:, retries: 1)
          attempts = 0

          headers = {
            "Authorization" => "Bearer #{access_token}",
            "X-Api-Version" => "Next",
          }

          begin
            response = get("/v3/person", headers:, query: { include: "PreviousNames" })
            response.parsed_response
          rescue HTTParty::ResponseError => e
            raise ApiError, "API request failed (HTTP #{e.response.code})"
          rescue Timeout::Error
            raise TimeoutError if (attempts += 1) > retries

            retry
          end
        end
      end
    end
  end
end
