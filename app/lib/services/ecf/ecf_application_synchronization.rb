module Services
  module Ecf
    class EcfApplicationSynchronization
      PER_PAGE = 50
      DEFAULT_LIMIT = 1000

      def initialize(limit = DEFAULT_LIMIT)
        @limit = limit
      end

      def call
        process_batch_applications
      rescue StandardError => e
        Rails.logger.error "An error occurred during application synchronization: #{e.message}"
      end

    private

      # Remove this code once all application statuses have been migrated.
      def process_batch_applications
        applications_to_sync.find_in_batches(batch_size: PER_PAGE) do |group|
          batch_runner(group.pluck(:ecf_id))
        end
      end

      def batch_runner(batch)
        uri = build_uri
        request = build_http_get_request(uri, batch)
        response = send_http_request(uri, request)
        handle_response(response)
      end

      def build_uri
        URI.parse("#{ENV['ECF_APP_BASE_URL']}/api/v1/npq/application_synchronizations")
      end

      def build_http_get_request(uri, ecf_ids)
        uri.query = "ecf_ids=#{ecf_ids.join(',')}"
        request = Net::HTTP::Get.new(uri)
        request["Authorization"] = "Bearer #{ENV['ECF_APP_BEARER_TOKEN']}"
        request
      end

      def applications_to_sync
        Application.where(lead_provider_approval_status: nil).limit(@limit)
      end

      def send_http_request(uri, request)
        Net::HTTP.start(uri.hostname, uri.port, use_ssl: use_ssl?, read_timeout: 30) do |http|
          http.request(request)
        end
      end

      def handle_response(response)
        if response.is_a?(Net::HTTPSuccess)
          data = response_data(response)
          data.each do |record|
            id = record.id
            lead_provider_approval_status = record.lead_provider_approval_status
            participant_outcome_state = record.participant_outcome_state

            application = Application.find_by(ecf_id: id)
            if application.present?
              application.update!(lead_provider_approval_status:, participant_outcome_state:)
            else
              Rails.logger.info("Application where ecf_id=#{id} is not synced yet")
            end
          end
        else
          raise "Failed to update application: #{response.message}"
        end
      end

      def response_data(response)
        data = JSON.parse(response.body)["data"]
        array = []
        data.each do |record|
          array << OpenStruct.new(
            id: record["attributes"]["id"],
            lead_provider_approval_status: record["attributes"]["lead_provider_approval_status"],
            participant_outcome_state: record["attributes"]["participant_outcome_state"],
          )
        end

        array
      end

      def use_ssl?
        build_uri.scheme == "https"
      end
    end
  end
end
