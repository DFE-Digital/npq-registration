module Services
  module Ecf
    class NpqApplicationUpdater
      def initialize(response_data)
        @response_data = JSON.parse(response_data)["data"]
      end

      def call
        filtered_applications = Application.where.not(ecf_id: nil)

        @response_data.each do |data|
          id = data["attributes"]["id"]
          lead_provider_approval_status = data["attributes"]["lead_provider_approval_status"]
          participant_outcome_state = data["attributes"]["participant_outcome_state"]

          application = filtered_applications.find_by(ecf_id: id)
          application.update!(lead_provider_approval_status:, participant_outcome_state:) if application.present?
        end
      end
    end
  end
end
