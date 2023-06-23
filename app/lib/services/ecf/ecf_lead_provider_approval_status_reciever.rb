module Services
  module Ecf
    class EcfLeadProviderApprovalStatusReceiver
      def call
        uri = URI.parse("#{ENV['ECF_APP_BASE_URL']}/api/v1/npq_synchronisation/send_lead_provider_approval_status_to_npq")
        request = Net::HTTP::Get.new(uri)
        request["Authorization"] = "Bearer #{ENV['ECF_APP_BEARER_TOKEN']}"

        response = Net::HTTP.start(uri.hostname, uri.port) do |http|
          http.request(request)
        end

        handle_response(response)
      rescue StandardError => e
        Rails.logger.error "An error occurred during lead provider approval status retrieval: #{e.message}"
      end

    private

      def handle_response(response)
        if response.is_a?(Net::HTTPSuccess)
          update_applications(JSON.parse(response.body)["data"])
        else
          raise "Failed to retrieve lead provider approval status: #{response.message}"
        end
      end

      def update_applications(status_data)
        filtered_applications = Application.where.not(ecf_id: nil)

        status_data.each do |data|
          retrieved_id = data["attributes"]["id"]
          retrieved_status = data["attributes"]["lead_provider_approval_status"]
          retrieved_state = data["attributes"]["participant_outcome_state"]

          application = filtered_applications.find_by(ecf_id: retrieved_id)
          application&.update!(
            lead_provider_approval_status: retrieved_status,
            participant_outcome_state: retrieved_state,
          )
        end
      end
    end
  end
end
