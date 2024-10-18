module Migration
  class ParityCheck
    class UnsupportedEnvironmentError < RuntimeError; end
    class EndpointsFileNotFoundError < RuntimeError; end

    attr_reader :endpoints_file_path

    def initialize(endpoints_file_path: "config/parity_check_endpoints.yml")
      @endpoints_file_path = endpoints_file_path
    end

    def run!
      raise UnsupportedEnvironmentError, "The parity check functionality is disabled for this environment" unless enabled?

      purge_comparisons!
      lead_providers.each(&method(:call_endpoints))
    end

  private

    def call_endpoints(lead_provider)
      endpoints.each do |method, paths|
        paths.each_key do |path|
          ecf_result = timed_response { get_request(lead_provider:, path:, app: :ecf) }
          npq_result = timed_response { get_request(lead_provider:, path:, app: :npq) }

          save_comparison!(lead_provider:, path:, method:, ecf_result:, npq_result:)
        end
      end
    end

    def save_comparison!(lead_provider:, path:, method:, ecf_result:, npq_result:)
      Migration::ParityCheck::ResponseComparison.create!({
        lead_provider:,
        request_path: path,
        request_method: method,
        ecf_response_status_code: ecf_result[:response].code,
        npq_response_status_code: npq_result[:response].code,
        ecf_response_body: ecf_result[:response].body,
        npq_response_body: npq_result[:response].body,
        ecf_response_time_ms: ecf_result[:response_ms],
        npq_response_time_ms: npq_result[:response_ms],
      })
    end

    def purge_comparisons!
      Migration::ParityCheck::ResponseComparison.destroy_all
    end

    def endpoints
      file = Rails.root.join(endpoints_file_path)

      raise EndpointsFileNotFoundError, "Endpoints file not found: #{endpoints_file_path}" unless File.exist?(file)

      YAML.load_file(file)
    end

    def enabled?
      Rails.application.config.npq_separation[:parity_check][:enabled]
    end

    def get_request(lead_provider:, path:, app:)
      HTTParty.get(url(app:, path:), headers: headers(token_provider.token(lead_provider:)))
    end

    def timed_response(&request)
      response = nil
      response_ms = Benchmark.realtime { response = request.call } * 1_000

      { response:, response_ms: }
    end

    def lead_providers
      @lead_providers ||= LeadProvider.all
    end

    def token_provider
      @token_provider ||= TokenProvider.new
    end

    def headers(token)
      {
        "Authorization" => "Bearer #{token}",
        "Accept" => "application/json",
        "Content-Type" => "application/json",
      }
    end

    def url(app:, path:)
      Rails.application.config.npq_separation[:parity_check]["#{app}_url".to_sym] + path
    end
  end
end
