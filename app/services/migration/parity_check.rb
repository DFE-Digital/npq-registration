module Migration
  class ParityCheck
    class UnsupportedEnvironmentError < RuntimeError; end

    attr_reader :token

    def initialize(token:)
      @token = token
    end

    def run
      raise UnsupportedEnvironmentError, "The parity check functionality is disabled for this environment" unless enabled?

      purge_comparisons!
      call_endpoints
    end

  private

    def call_endpoints
      endpoints.each do |method, paths|
        paths.each do |path, options|
          body = (options&.dig("body") || {}).to_json
          ecf_response = ecf_connection.request(method:, path:, body:)
          npq_response = npq_connection.request(method:, path:, body:)

          save_comparison!(path:, method:, ecf_response:, npq_response:)
        end
      end
    end

    def save_comparison!(path:, method:, ecf_response:, npq_response:)
      comparison = HashDiff::Comparison.new(ecf_response.body, npq_response.body)
      status_codes_match = ecf_response.status == npq_response.status

      ParityCheckComparison.create!({
        path:,
        method:,
        ecf_status: ecf_response.status,
        npq_status: npq_response.status,
        ecf_response: ecf_response.body,
        npq_response: npq_response.body,
        equal: status_codes_match && comparison.diff.empty?,
      })
    end

    def purge_comparisons!
      ParityCheckComparison.destroy_all
    end

    def endpoints
      YAML.load_file(Rails.root.join("config/parity_check_endpoints.yml"))
    end

    def ecf_connection
      @ecf_connection ||= Excon.new(url(app: :ecf), persistent: true, headers:)
    end

    def npq_connection
      @npq_connection ||= Excon.new(url(app: :npq), persistent: true, headers:)
    end

    def enabled?
      Rails.application.config.npq_separation[:parity_check][:enabled]
    end

    def headers
      {
        "Authentication" => "Bearer: #{token}",
        "Accept" => "application/json",
        "Content-Type" => "application/json",
      }
    end

    def url(app:)
      Rails.application.config.npq_separation[:parity_check]["#{app}_url".to_sym]
    end
  end
end
