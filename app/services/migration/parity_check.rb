module Migration
  class ParityCheck
    class UnsupportedEnvironmentError < RuntimeError; end
    class EndpointsFileNotFoundError < RuntimeError; end
    class NotPreparedError < RuntimeError; end

    attr_reader :endpoints_file_path

    class << self
      def prepare!
        Rails.cache.write(:parity_check_started_at, Time.zone.now)
        Rails.cache.write(:parity_check_completed_at, nil)

        Migration::ParityCheck::ResponseComparison.destroy_all
      end

      def running?
        started_at && !completed_at
      end

      def completed?
        completed_at.present?
      end

      def started_at
        Rails.cache.read(:parity_check_started_at)
      end

      def completed_at
        Rails.cache.read(:parity_check_completed_at)
      end
    end

    def initialize(endpoints_file_path: "config/parity_check_endpoints.yml")
      @endpoints_file_path = endpoints_file_path
    end

    def run!
      raise UnsupportedEnvironmentError, "The parity check functionality is disabled for this environment" unless enabled?

      lead_providers.each(&method(:call_endpoints))

      finalise!
    end

  private

    def prepared?
      self.class.started_at.present?
    end

    def call_endpoints(lead_provider)
      raise NotPreparedError, "You must call prepare! before running the parity check" unless prepared?

      endpoints.each do |method, paths|
        paths.each_key do |path|
          ecf_result = timed_response { get_request(lead_provider:, path:, app: :ecf) }
          npq_result = timed_response { get_request(lead_provider:, path:, app: :npq) }

          save_comparison!(lead_provider:, path:, method:, ecf_result:, npq_result:)
        end
      end
    end

    def finalise!
      Rails.cache.write(:parity_check_completed_at, Time.zone.now)
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
