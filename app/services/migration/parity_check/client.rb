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

    # These are public for ease of testing
    def post_declaration_payload
      application = lead_provider.applications
        .includes(:user)
        .left_joins(:declarations)
        .where(training_status: :active, declarations: { id: nil })
        .accepted
        .order("RANDOM()")
        .first

      participant_id = application.user.ecf_id
      course_identifier = application.course.identifier
      declaration_date = 1.day.ago.rfc3339

      {
        type: "participant-declaration",
        attributes: {
          participant_id:,
          declaration_type: :started,
          declaration_date:,
          course_identifier:,
        },
      }
    end

    def post_participant_outcome_payload
      participant = User.includes(applications: :course).find_by(ecf_id: path_id)

      {
        type: "npq-outcome-confirmation",
        attributes: {
          course_identifier: participant.applications.accepted.first.course.identifier,
          state: :passed,
          completion_date: 1.day.ago.rfc3339,
        },
      }
    end

    def put_participant_resume_payload
      participant = User.includes(applications: :course).find_by(ecf_id: path_id)

      {
        type: "participant-resume",
        attributes: {
          course_identifier: participant.applications.accepted.first.course.identifier,
        },
      }
    end

    def put_participant_defer_payload
      participant = User.includes(applications: :course).find_by(ecf_id: path_id)

      {
        type: "participant-defer",
        attributes: {
          course_identifier: participant.applications.accepted.first.course.identifier,
          reason: Participants::Defer::DEFERRAL_REASONS.sample,
        },
      }
    end

    def put_participant_withdraw_payload
      participant = User.includes(applications: :course).find_by(ecf_id: path_id)

      {
        type: "participant-withdraw",
        attributes: {
          course_identifier: participant.applications.accepted.first.course.identifier,
          reason: Participants::Withdraw::WITHDRAWAL_REASONS.sample,
        },
      }
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
      HTTParty.get(url(app:), query:, headers:, timeout: 5.minutes)
    end

    def post_request(app:)
      HTTParty.post(url(app:), body:, query:, headers:)
    end

    def put_request(app:)
      HTTParty.put(url(app:), body:, query:, headers:)
    end

    def body
      @body ||= begin
        return {} unless options.key?(:payload)

        data = options[:payload].is_a?(Hash) ? options[:payload] : send(options[:payload])

        { data: }.to_json
      end
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
        return path unless path.include?(":id")

        path.sub(":id", path_id)
      end
    end

    def path_id
      return nil unless options[:id]

      raise UnsupportedIdOption, "Unsupported id option: #{options[:id]}" unless respond_to?(options[:id], true)

      send(options[:id]).to_s
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

    def application_ecf_id_for_accept_with_funded_place
      lead_provider
        .applications
        .eligible_for_funding
        .where(lead_provider_approval_status: :pending)
        .where.not(user_id: Application.group(:user_id).having("COUNT(*) > 1").pluck(:user_id))
        .order("RANDOM()")
        .limit(1)
        .pick(:ecf_id)
    end

    def application_ecf_id_for_accept_without_funded_place
      lead_provider
        .applications
        .where(lead_provider_approval_status: :pending, eligible_for_funding: false)
        .where.not(user_id: Application.group(:user_id).having("COUNT(*) > 1").pluck(:user_id))
        .order("RANDOM()")
        .limit(1)
        .pick(:ecf_id)
    end

    def application_ecf_id_for_reject
      lead_provider
        .applications
        .where(lead_provider_approval_status: :pending)
        .order("RANDOM()")
        .limit(1)
        .pick(:ecf_id)
    end

    def participant_ecf_id_for_create_outcome
      User
        .includes(:applications, :declarations)
        .where(applications: { lead_provider:, lead_provider_approval_status: :accepted })
        .where(declarations: { declaration_type: :completed })
        .order("RANDOM()")
        .limit(1)
        .pick(:ecf_id)
    end

    def application_ecf_id_for_change_from_funded_place
      lead_provider
        .applications
        .accepted
        .where(funded_place: true)
        .pick(:ecf_id)
    end

    def declaration_ecf_id_for_void
      Declaration
        .where(state: Declaration::CHANGEABLE_STATES, lead_provider:)
        .pick(:ecf_id)
    end

    def declaration_ecf_id_for_clawback
      Declaration
        .includes(:statement_items)
        .where(lead_provider:, state: :paid)
        .where.not(id: StatementItem.where(declaration_id: Declaration.select(:id)).where(state: StatementItem::REFUNDABLE_STATES).select(:declaration_id))
        .pick(:ecf_id)
    end

    def participant_ecf_id_for_resume
      User
        .includes(:applications)
        .where(applications: { lead_provider:, lead_provider_approval_status: :accepted, training_status: %i[deferred withdrawn] })
        .order("RANDOM()")
        .limit(1)
        .pick(:ecf_id)
    end

    def participant_ecf_id_for_defer
      User
        .includes(:applications, :declarations)
        .where(applications: { lead_provider:, lead_provider_approval_status: :accepted, training_status: :active })
        .where.not(declarations: { id: nil })
        .order("RANDOM()")
        .limit(1)
        .pick(:ecf_id)
    end

    def participant_ecf_id_for_withdraw
      User
        .includes(:applications, :declarations)
        .where(applications: { lead_provider:, lead_provider_approval_status: :accepted, training_status: %i[deferred active], declarations: { declaration_type: :started } })
        .order("RANDOM()")
        .limit(1)
        .pick(:ecf_id)
    end
  end
end
