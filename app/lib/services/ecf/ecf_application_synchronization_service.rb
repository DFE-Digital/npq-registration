module Services
  module Ecf
    class EcfApplicationSynchronizationService
      def call
        uri = build_uri
        required_application_ids = fetch_required_application_ids
        params = build_request_params(required_application_ids)
        request = build_http_get_request(uri, params)
        response = send_http_request(uri, request)
        handle_response(response)
      rescue StandardError => e
        Rails.logger.error "An error occurred during application synchronization: #{e.message}"
      end

    private

      def build_uri
        URI.parse("#{ENV['ECF_APP_BASE_URL']}/api/v1/npq/application_synchronizations#index")
      end

      def fetch_required_application_ids
        Application.where(lead_provider_approval_status: nil).limit(1000).pluck(:ecf_id)
      end

      def build_request_params(application_ids)
        { ids: application_ids.join(",") }
      end

      def build_http_get_request(uri, params)
        request = Net::HTTP::Get.new(uri)
        request["Authorization"] = "Bearer #{ENV['ECF_APP_BEARER_TOKEN']}"
        request.body = URI.encode_www_form(params)
        request
      end

      def send_http_request(uri, request)
        Net::HTTP.start(uri.hostname, uri.port) do |http|
          http.request(request)
        end
      end

      def handle_response(response)
        if response.is_a?(Net::HTTPSuccess)
          NpqApplicationUpdaterJob.perform_now(response.body)
        else
          raise "Failed to synchronize application: #{response.message}"
        end
      end
    end
  end
end
