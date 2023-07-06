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
        URI.parse("#{ENV['ECF_APP_BASE_URL']}/api/v1/npq/application_synchronizations")
      end

      def build_http_get_request(uri)
        request = Net::HTTP::Get.new(uri)
        request["Authorization"] = "Bearer #{ENV['ECF_APP_BEARER_TOKEN']}"
        request
      end

      def send_http_request(uri, request)
        Net::HTTP.start(uri.hostname, uri.port, use_ssl: use_ssl?, read_timeout: 30) do |http|
          http.request(request)
        end
      end

      def handle_response(response)
        if response.is_a?(Net::HTTPSuccess)
          data = response_data(response)
          data["data"].each do |record|
            SyncApplicationStatusJob.perform_now(record)
          end
        else
          raise "Failed to synchronize application: #{response.message}"
        end
      end

      def response_data(response)
        JSON.parse(response.body)
      end

      def use_ssl?
        build_uri.scheme == "https"
      end
    end
  end
end
