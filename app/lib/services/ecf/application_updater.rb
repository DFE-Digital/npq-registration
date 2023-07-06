module Services
  module Ecf
    class ApplicationUpdater
      def initialize(data)
        @data = data
      end

      def call
        id = @data["attributes"]["id"]
        lead_provider_approval_status = @data["attributes"]["lead_provider_approval_status"]
        participant_outcome_state = @data["attributes"]["participant_outcome_state"]

        application = Application.find_by(ecf_id: id)
        application.update!(lead_provider_approval_status:, participant_outcome_state:) if application.present?
      end
    end
  end
end
