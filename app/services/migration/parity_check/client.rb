module Migration
  class ParityCheck::Client
    attr_reader :lead_provider, :method, :path, :options

    def initialize(lead_provider:, method:, path:, options:)
      @lead_provider = lead_provider
      @method = method
      @path = path
      @options = options || {}
    end

    def make_requests(&block)
      ecf_result = timed_response { send("#{method}_request", lead_provider:, path:, app: :ecf) }
      npq_result = timed_response { send("#{method}_request", lead_provider:, path:, app: :npq) }

      block.call(ecf_result, npq_result, nil)
    end

  private

    def timed_response(&request)
      response = nil
      response_ms = Benchmark.realtime { response = request.call } * 1_000

      { response:, response_ms: }
    end

    def get_request(lead_provider:, path:, app:)
      HTTParty.get(url(app:, path:), headers: headers(token_provider.token(lead_provider:)))
    end

    def token_provider
      @token_provider ||= Migration::ParityCheck::TokenProvider.new
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
