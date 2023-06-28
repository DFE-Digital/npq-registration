module Services
  module Ecf
    class EcfApplicationSynchronizationService
      def call
        uri = URI.parse("#{ENV['ECF_APP_BASE_URL']}/api/v1/npq/application_synchronizations#index")
        required_application_ids = Application.where(lead_provider_approval_status: nil).limit(1000).pluck(:ecf_id)
        params = { ids: required_application_ids }
        request = Net::HTTP::Get.new(uri)
        request["Authorization"] = "Bearer #{ENV['ECF_APP_BEARER_TOKEN']}"

        response = Net::HTTP.start(uri.hostname, uri.port) do |http|
          http.request(request, params.to_json)
        end

        handle_response(response)
      rescue StandardError => e
        Rails.logger.error "An error occurred during application synchronization: #{e.message}"
      end

    private

      def handle_response(response)
        if response.is_a?(Net::HTTPSuccess)
          update_statuses_in_npq_applications(JSON.parse(response.body)["data"])
        else
          raise "Failed to synchronize application: #{response.message}"
        end
      end

      def update_statuses_in_npq_applications(response_data)
        filtered_applications = Application.where.not(ecf_id: nil)

        response_data.each do |data|
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
