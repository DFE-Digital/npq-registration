module TeacherRecordService
  module V3
    class Person
      include HTTParty

      format :json
      base_uri ENV["TRS_API_URL"]
      default_timeout 5.seconds

      def self.find_with_token(access_token:)
        headers = {
          "Authorization" => "Bearer #{access_token}",
          "Accept" => "application/json",
          "X-Api-Version" => "Next",
        }

        response = get("/v3/person", headers:)

        if response.success?
          response.parsed_response
        else
          nil
        end
      rescue Timeout::Error => e
        raise e
      end
    end
  end
end
