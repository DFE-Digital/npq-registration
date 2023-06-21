class ReceiveLeadProviderApprovalStatusFromEcf < ApplicationJob
  queue_as :default
  def perform
    begin
      uri = URI.parse("#{ENV['ECF_APP_BASE_URL']}/api/v3/npq-applications/send_lead_provider_approval_status_to_npq")
      request = Net::HTTP::Get.new(uri)
      request["Authorization"] = "Bearer #{ENV['ECF_APP_BEARER_TOKEN']}"
      response = Net::HTTP.start(uri.hostname, uri.port) do |http|
        http.request(request)
      end
      if response.is_a?(Net::HTTPSuccess)
        response_data = JSON.parse(response.body)
        filtered_applications = Application.where.not(ecf_id: nil)
        response_data["data"].map do |status_data|
          retrieved_id = status_data["attributes"]["id"]
          retrieved_status = status_data["attributes"]["lead_provider_approval_status"]
          application = filtered_applications.find_by(ecf_id: retrieved_id)
          application.update!(lead_provider_approval_status: retrieved_status) if application.present?
        end
      else
        response_message = response.message
        raise "Failed to retrieve lead provider approval status: #{response_message}"
      end
    rescue StandardError => e
      Rails.logger.error "An error occurred during lead provider approval status retrieval: #{e.message}"
    end
  end
end
