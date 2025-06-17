module Dqt
  module V1
    class Teacher
      include HTTParty

      format :json
      base_uri ENV["DQT_API_URL"]
      headers "Authorization" => "Bearer #{ENV["DQT_API_KEY"]}"
      default_timeout 5.seconds

      def self.find(trn:, birthdate:, nino: nil)
        path = "/v1/teachers/#{trn}"
        query = {
          birthdate:,
        }
        query[:nino] = nino if nino

        Rails.logger.info("DQT API request started")

        response = get(path, query:)

        Rails.logger.info("DQT API response: #{response.code}")

        if response.success?
          response.slice(
            "trn",
            "state_name",
            "name",
            "dob",
            "ni_number",
            "active_alert",
          )
        end
      rescue Timeout::Error => e
        Rails.logger.error("DQT API request timed out: #{e.class} #{e.message}")
        raise e
      end
    end
  end
end
