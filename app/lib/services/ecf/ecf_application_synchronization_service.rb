module Services
  module Ecf
    class EcfApplicationSynchronizationService
      def call
        uri = build_uri
        request = build_http_get_request(uri)
        response = send_http_request(uri, request)
        handle_response(response)
      rescue StandardError => e
        Rails.logger.error "An error occurred during application synchronization: #{e.message}"
      end

    private

      def build_uri
        URI.parse("#{ENV['ECF_APP_BASE_URL']}/api/v1/npq/application_synchronizations#index")
      end

      def build_http_get_request(uri)
        request = Net::HTTP::Get.new(uri)
        request["Authorization"] = "Bearer #{ENV['ECF_APP_BEARER_TOKEN']}"
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
