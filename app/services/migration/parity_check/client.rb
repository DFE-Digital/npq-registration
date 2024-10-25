module Migration
  class ParityCheck::Client
    class UnsupportedIdOption < RuntimeError; end

    attr_reader :lead_provider, :method, :path, :options, :page

    PAGINATION_PER_PAGE = 10

    def initialize(lead_provider:, method:, path:, options:)
      @lead_provider = lead_provider
      @method = method
      @path = path
      @options = options || {}
      @page = 1 if paginate?
    end

    def make_requests(&block)
      loop do
        ecf_result = timed_response { send("#{method}_request", app: :ecf) }
        npq_result = timed_response { send("#{method}_request", app: :npq) }

        block.call(ecf_result, npq_result, formatted_path, page)

        break unless next_page?(ecf_result, npq_result)

        @page += 1
      end
    end

  private

    def next_page?(ecf_response, npq_response)
      return false unless paginate?
      return false unless responses_match?(ecf_response, npq_response)

      pages_remain?(ecf_response, npq_response)
    end

    def responses_match?(ecf_response, npq_response)
      ecf_response[:response].code == npq_response[:response].code &&
        ecf_response[:response].body == npq_response[:response].body
    end

    def pages_remain?(ecf_response, npq_response)
      [ecf_response[:response].body, npq_response[:response].body].any? do |body|
        JSON.parse(body)["data"]&.size == PAGINATION_PER_PAGE
      rescue JSON::ParserError
        false
      end
    end

    def paginate?
      options[:paginate]
    end

    def timed_response(&request)
      response = nil
      response_ms = Benchmark.realtime { response = request.call } * 1_000

      { response:, response_ms: }
    end

    def get_request(app:)
      HTTParty.get(url(app:), query:, headers:)
    end

    def token_provider
      @token_provider ||= Migration::ParityCheck::TokenProvider.new
    end

    def query
      return unless paginate?

      { page: { page:, per_page: PAGINATION_PER_PAGE } }
    end

    def headers
      {
        "Authorization" => "Bearer #{token_provider.token(lead_provider:)}",
        "Accept" => "application/json",
        "Content-Type" => "application/json",
      }
    end

    def url(app:)
      Rails.application.config.npq_separation[:parity_check]["#{app}_url".to_sym] + formatted_path
    end

    def formatted_path
      @formatted_path ||= begin
        return path unless options[:id] && path.include?(":id")

        raise UnsupportedIdOption, "Unsupported id option: #{options[:id]}" unless respond_to?(options[:id], true)

        path.sub(":id", send(options[:id]).to_s)
      end
    end

    def application_ecf_id
      lead_provider.applications.order("RANDOM()").limit(1).pick(:ecf_id)
    end

    def declaration_ecf_id
      Declaration.where(lead_provider:).order("RANDOM()").limit(1).pick(:ecf_id)
    end

    def participant_outcome_ecf_id
      ParticipantOutcome
        .includes(declaration: { application: :user })
        .where(declaration: { lead_provider: })
        .order("RANDOM()")
        .limit(1)
        .pick("users.ecf_id")
    end

    def participant_ecf_id
      User
        .includes(:applications)
        .where(applications: { lead_provider:, lead_provider_approval_status: :accepted })
        .order("RANDOM()")
        .limit(1)
        .pick(:ecf_id)
    end

    def statement_ecf_id
      lead_provider.statements.order("RANDOM()").limit(1).pick(:ecf_id)
    end
  end
end
