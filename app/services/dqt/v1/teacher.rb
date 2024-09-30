module Dqt
  module V1
    class Teacher
      include HTTParty

      format :json
      base_uri ENV["DQT_API_URL"]
      headers "Authorization" => "Bearer #{ENV["DQT_API_KEY"]}"

      def self.validate_trn(trn:, birthdate:, nino: nil)
        path = "/v1/teachers/#{trn}"
        query = {
          birthdate:,
        }
        query[:nino] = nino if nino

        response = get(path, query:)

        if response.success?
          response.slice("trn", "active_alert")
        end
      end
    end
  end
end
