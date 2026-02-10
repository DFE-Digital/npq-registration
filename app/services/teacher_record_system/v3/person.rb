module TeacherRecordSystem
  module V3
    class Person
      include HTTParty

      format :json
      base_uri ENV["TRS_API_URL"]
      default_timeout 5.seconds

      def self.find_with_token(access_token:, retries: 1)
        attempts = 0

        headers = {
          "Authorization" => "Bearer #{access_token}",
          "X-Api-Version" => "Next",
        }

        begin
          response = get("/v3/person", headers:, query: { include: "PreviousNames" })

          if response.success?
            response.parsed_response
          end
        rescue Timeout::Error
          raise TimeoutError if (attempts += 1) > retries

          retry
        end
      end
    end
  end
end
