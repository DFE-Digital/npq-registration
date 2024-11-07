module Migration
  class PerformanceTest::Client
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
        ecf_result = parse_results(send("#{method}_request", app: :ecf))
        npq_result = parse_results(send("#{method}_request", app: :npq))

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

    def parse_results(wrk_output)
      latency_avg, latency_stdev, latency_max, latency_plus_minus_stdev = wrk_output.match(/Latency\s+([^\s]+)\s+([^\s+]+)\s+([^\s+]+)\s+([^\s]+)%/).captures
      req_per_sec_avg, req_per_sec_stdev, req_per_sec_max, req_per_sec_plus_minus_stdev = wrk_output.match(/Req\/Sec\s+([^\s]+)\s+([^\s+]+)\s+([^\s+]+)\s+([^\s]+)%/).captures

      {
        threads: wrk_output[/(\d+) threads/, 1].to_i,
        connections: wrk_output[/(\d+) connections/, 1].to_i,
        request: {
          count: wrk_output[/(\d+) requests/, 1].to_i,
          per_second: wrk_output[/Requests\/sec:\s+([^\\n+]+)/, 1].to_f,
          transfer_per_second: wrk_output[/Transfer\/sec:\s+([^\\n+]+)/, 1],
          non_200_300_responses: wrk_output[/Non-2xx or 3xx responses:\s+(\d+)/, 1].to_i,
        },
        latency: {
          avg: convert_to_ms(latency_avg),
          stdev: convert_to_ms(latency_stdev),
          max: convert_to_ms(latency_max),
          plus_minus_stdev_percent: latency_plus_minus_stdev.to_f,
        },
        req_per_sec: {
          avg: req_per_sec_avg.to_f,
          stdev: req_per_sec_stdev.to_f,
          max: req_per_sec_max.to_f,
          plus_minus_stdev_percent: req_per_sec_plus_minus_stdev.to_f,
        },
        socket_errors: {
          connect: wrk_output[/connect (\d+)/, 1].to_i,
          read: wrk_output[/read (\d+)/, 1].to_i,
          write: wrk_output[/write (\d+)/, 1].to_i,
          timeout: wrk_output[/timeout (\d+)/, 1].to_i,
        },
        raw: wrk_output,
      }
    end

    def convert_to_ms(value)
      if value.include?("ms")
        value.to_f
      elsif value.include?("s")
        value.to_f * 1000
      else
        raise "Unsupported time value: #{value}"
      end
    end

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

    def get_request(app:)
      lua_script_path = Rails.root.join("config/get.request.lua")

      lua_script = <<~LUA
        wrk.method = "GET"
        #{headers.map { |k, v| %(wrk.headers["#{k}"] = "#{v}") }.join("\n")}
      LUA

      File.write(lua_script_path, lua_script)

      wrk_command(lua_script_path, app:)
    end

    def post_request(app:)
      lua_script_path = Rails.root.join("config/post.request.lua")

      lua_script = <<~LUA
        wrk.method = "POST"
        #{headers.map { |k, v| %(wrk.headers["#{k}"] = "#{v}") }.join("\n")}
        wrk.body = '#{body}'
      LUA

      File.write(lua_script_path, lua_script)

      wrk_command(lua_script_path, app:)
    end

    def put_request(app:)
      lua_script_path = Rails.root.join("config/put.request.lua")

      lua_script = <<~LUA
        wrk.method = "PUT"
        #{headers.map { |k, v| %(wrk.headers["#{k}"] = "#{v}") }.join("\n")}
        wrk.body = '#{body}'
      LUA

      File.write(lua_script_path, lua_script)

      wrk_command(lua_script_path, app:)
    end

    def wrk_command(lua_script_path, app:)
      puts "Running wrk command for #{app} with path: #{formatted_path} and provider: #{lead_provider.name}"

      `wrk -t16 -c80 -d10s -s #{lua_script_path} #{url(app:)}`
    end

    def headers
      {
        "Authorization" => "Bearer #{token_provider.token(lead_provider:)}",
        "Accept" => "application/json",
        "Content-Type" => "application/json",
      }
    end

    def token
      token_provider.token(lead_provider:)
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

    def url(app:)
      uri = URI(Rails.application.config.npq_separation[:parity_check]["#{app}_url".to_sym] + formatted_path)
      uri.query = URI.encode_www_form(query) if query
      uri.to_s
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
