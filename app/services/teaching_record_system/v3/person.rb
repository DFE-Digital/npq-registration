module TeachingRecordSystem
  module V3
    class Person
      include HTTParty

      format :json
      base_uri ENV["TRS_API_URL"]
      default_timeout 5.seconds

      class << self
        def find_with_token(access_token:, retries: 1)
          attempts = 0

          headers = {
            "Authorization" => "Bearer #{access_token}",
            "X-Api-Version" => "Next",
          }

          begin
            response = get("/v3/person", headers:, query: { include: "PreviousNames" })

            return response.parsed_response if response.success?

            raise ApiError, build_error_message(response)
          rescue Timeout::Error
            raise TimeoutError if (attempts += 1) > retries

            retry
          end
        end

      private

        def build_error_message(response)
          case response.code
          when 401
            "Unauthorized: Access token is invalid or expired (HTTP 401)"
          when 403
            "Forbidden: Access denied (HTTP 403)"
          when 404
            "Teaching record not found (HTTP 404)"
          when 500..599
            "Teaching Record System server error (HTTP #{response.code})"
          else
            "API request failed (HTTP #{response.code})"
          end
        end
      end
    end
  end
end
