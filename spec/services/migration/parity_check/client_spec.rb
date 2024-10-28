require "rails_helper"

RSpec.describe Migration::ParityCheck::Client do
  let(:lead_provider) { create(:lead_provider) }
  let(:path) { "/api/path" }
  let(:method) { :get }
  let(:options) { {} }
  let(:instance) { described_class.new(lead_provider:, method:, path:, options:) }
  let(:ecf_url) { "http://ecf.example.com" }
  let(:npq_url) { "http://npq.example.com" }
  let(:keys) { { lead_provider.ecf_id => SecureRandom.uuid } }

  before do
    allow(Rails.application.config).to receive(:npq_separation) do
      {
        parity_check: {
          enabled: true,
          ecf_url:,
          npq_url:,
        },
      }
    end

    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("PARITY_CHECK_KEYS").and_return(keys.to_json)
  end

  describe "#initialize" do
    it { expect(instance.lead_provider).to eq(lead_provider) }
    it { expect(instance.path).to eq(path) }
    it { expect(instance.method).to eq(method) }
    it { expect(instance.options).to eq(options) }
    it { expect(instance.page).to be_nil }

    context "when options is nil" do
      let(:options) { nil }

      it { expect(instance.options).to eq({}) }
    end

    context "when paginate is true" do
      let(:options) { { paginate: true } }

      it { expect(instance.page).to eq(1) }
    end
  end

  shared_examples "makes valid requests and yields the results" do
    it "makes a request to each service" do
      instance.make_requests {}

      expect(ecf_requests.count).to eq(1)
      expect(npq_requests.count).to eq(1)
    end

    it "makes requests with the correct path and headers" do
      instance.make_requests {}

      requests.each do |request|
        expect(request.uri.path).to eq(path)
        expect(request.headers["Accept"]).to eq("application/json")
        expect(request.headers["Content-Type"]).to eq("application/json")
      end
    end

    it "makes requests with a valid authorization token for the lead provider" do
      instance.make_requests {}

      ecf_token = ecf_requests.first.headers["Authorization"].partition("Bearer ").last
      expect(ecf_token).to eq(keys[lead_provider.ecf_id])

      npq_token = npq_requests.first.headers["Authorization"].partition("Bearer ").last
      expect(npq_token).to eq(keys[lead_provider.ecf_id])
    end

    it "yields the result of each request to the block" do
      instance.make_requests do |ecf_result, npq_result, formatted_path, page|
        expect(ecf_result[:response].code).to eq(200)
        expect(ecf_result[:response].body).to eq("ecf_response_body")
        expect(ecf_result[:response_ms]).to be >= 0

        expect(npq_result[:response].code).to eq(201)
        expect(npq_result[:response].body).to eq("npq_response_body")
        expect(npq_result[:response_ms]).to be >= 0

        expect(formatted_path).to eq(path)
        expect(page).to be_nil
      end
    end
  end

  describe "#make_requests" do
    let(:requests) { WebMock::RequestRegistry.instance.requested_signatures.hash.keys }
    let(:ecf_requests) { requests.select { |r| r.uri.host.include?("ecf") } }
    let(:npq_requests) { requests.select { |r| r.uri.host.include?("npq") } }

    context "when making a POST request" do
      let(:method) { :post }
      let(:options) { { payload: { type: "type", attributes: { "key": "value" } } } }
      let(:body) { { data: options[:payload] } }

      before do
        stub_request(:post, "#{ecf_url}#{path}").with(body:).to_return(status: 200, body: "ecf_response_body")
        stub_request(:post, "#{npq_url}#{path}").with(body:).to_return(status: 201, body: "npq_response_body")
      end

      include_context "makes valid requests and yields the results"

      context "when the payload is not specified" do
        let(:options) { {} }
        let(:body) { {} }

        include_context "makes valid requests and yields the results"
      end

      context "when the payload is a method instead of a hash" do
        let(:options) { { payload: :post_declaration_payload } }

        before do
          create(:application, :accepted, lead_provider:)

          stub_request(:post, "#{ecf_url}#{path}").to_return(status: 200, body: "ecf_response_body")
          stub_request(:post, "#{npq_url}#{path}").to_return(status: 201, body: "npq_response_body")
        end

        include_context "makes valid requests and yields the results"

        it "uses the method to get the payload" do
          instance.make_requests {}

          requests.each do |request|
            body = JSON.parse(request.body)

            expect(body).to include({
              "data" => {
                "type" => "participant-declaration",
                "attributes" => a_hash_including({
                  "declaration_type" => "started",
                }),
              },
            })
          end
        end
      end
    end

    context "when making a PUT request" do
      let(:method) { :put }
      let(:options) { { payload: { type: "type", attributes: { "key": "value" } } } }
      let(:body) { { data: options[:payload] } }

      before do
        stub_request(:put, "#{ecf_url}#{path}").with(body:).to_return(status: 200, body: "ecf_response_body")
        stub_request(:put, "#{npq_url}#{path}").with(body:).to_return(status: 201, body: "npq_response_body")
      end

      include_context "makes valid requests and yields the results"

      context "when the payload is not specified" do
        let(:options) { {} }
        let(:body) { {} }

        include_context "makes valid requests and yields the results"
      end

      context "when the payload is a method instead of a hash" do
        let(:options) { { id: :participant_ecf_id_for_resume, payload: :put_participant_resume_payload } }

        before do
          create(:application, :accepted, :deferred, lead_provider:)

          stub_request(:put, "#{ecf_url}#{path}").to_return(status: 200, body: "ecf_response_body")
          stub_request(:put, "#{npq_url}#{path}").to_return(status: 201, body: "npq_response_body")
        end

        include_context "makes valid requests and yields the results"

        it "uses the method to get the payload" do
          instance.make_requests {}

          requests.each do |request|
            body = JSON.parse(request.body)

            expect(body).to include({
              "data" => {
                "type" => "participant-resume",
                "attributes" => a_hash_including({
                  "course_identifier" => /.*/,
                }),
              },
            })
          end
        end
      end
    end

    context "when making a GET request" do
      let(:method) { :get }

      before do
        stub_request(:get, "#{ecf_url}#{path}").to_return(status: 200, body: "ecf_response_body")
        stub_request(:get, "#{npq_url}#{path}").to_return(status: 201, body: "npq_response_body")
      end

      include_context "makes valid requests and yields the results"

      context "when paginate is true" do
        let(:options) { { paginate: true } }

        before { stub_const("Migration::ParityCheck::Client::PAGINATION_PER_PAGE", 2) }

        context "when there is only one page of results" do
          before do
            stub_request(:get, "#{ecf_url}#{path}")
              .with(query: { page: { page: 1, per_page: 2 } })
              .to_return(status: 200, body: { data: [1] }.to_json)

            stub_request(:get, "#{npq_url}#{path}")
              .with(query: { page: { page: 1, per_page: 2 } })
              .to_return(status: 200, body: { data: [1] }.to_json)
          end

          it "makes a single request to each service for the first page" do
            instance.make_requests {}

            expect(ecf_requests.count).to eq(1)
            expect(URI.decode_uri_component(ecf_requests.first.uri.query)).to eq("page[page]=1&page[per_page]=2")

            expect(npq_requests.count).to eq(1)
            expect(URI.decode_uri_component(npq_requests.first.uri.query)).to eq("page[page]=1&page[per_page]=2")
          end

          it "yields the result of each request to the block" do
            instance.make_requests do |ecf_result, npq_result, formatted_path, page|
              expect(ecf_result[:response].code).to eq(200)
              expect(ecf_result[:response].body).to eq({ data: [1] }.to_json)
              expect(ecf_result[:response_ms]).to be >= 0

              expect(npq_result[:response].code).to eq(200)
              expect(npq_result[:response].body).to eq({ data: [1] }.to_json)
              expect(npq_result[:response_ms]).to be >= 0

              expect(formatted_path).to eq(path)
              expect(page).to eq(1)
            end
          end
        end

        context "when there are two pages of results and the responses from the first page match" do
          before do
            stub_request(:get, "#{ecf_url}#{path}")
              .with(query: { page: { page: 1, per_page: 2 } })
              .to_return(status: 200, body: { data: [1, 2] }.to_json)
            stub_request(:get, "#{ecf_url}#{path}")
              .with(query: { page: { page: 2, per_page: 2 } })
              .to_return(status: 200, body: { data: [3] }.to_json)

            stub_request(:get, "#{npq_url}#{path}")
              .with(query: { page: { page: 1, per_page: 2 } })
              .to_return(status: 200, body: { data: [1, 2] }.to_json)
            stub_request(:get, "#{npq_url}#{path}")
              .with(query: { page: { page: 2, per_page: 2 } })
              .to_return(status: 200, body: { data: [3] }.to_json)
          end

          it "makes a single request to each service for all pages" do
            instance.make_requests {}

            expect(ecf_requests.count).to eq(2)
            expect(URI.decode_uri_component(ecf_requests.first.uri.query)).to eq("page[page]=1&page[per_page]=2")
            expect(URI.decode_uri_component(ecf_requests.last.uri.query)).to eq("page[page]=2&page[per_page]=2")

            expect(npq_requests.count).to eq(2)
            expect(URI.decode_uri_component(npq_requests.first.uri.query)).to eq("page[page]=1&page[per_page]=2")
            expect(URI.decode_uri_component(npq_requests.last.uri.query)).to eq("page[page]=2&page[per_page]=2")
          end

          it "yields the result of each request to the block" do
            expected_page = 0

            instance.make_requests do |ecf_result, npq_result, formatted_path, page|
              expected_page += 1
              expect(page).to eq(expected_page)
              expect(formatted_path).to eq(path)

              case page
              when 1
                expect(ecf_result[:response].body).to eq({ data: [1, 2] }.to_json)
                expect(npq_result[:response].body).to eq({ data: [1, 2] }.to_json)
              when 2
                expect(ecf_result[:response].body).to eq({ data: [3] }.to_json)
                expect(npq_result[:response].body).to eq({ data: [3] }.to_json)
              end
            end

            expect(expected_page).to eq(2)
          end
        end

        context "when there are two pages of results and the first page responses do not match" do
          before do
            stub_request(:get, "#{ecf_url}#{path}")
              .with(query: { page: { page: 1, per_page: 2 } })
              .to_return(status: 200, body: { data: [1, 2] }.to_json)
            stub_request(:get, "#{npq_url}#{path}")
              .with(query: { page: { page: 1, per_page: 2 } })
              .to_return(status: 200, body: { data: [3] }.to_json)
          end

          it "stops at the first page of responses" do
            instance.make_requests {}

            expect(ecf_requests.count).to eq(1)
            expect(URI.decode_uri_component(ecf_requests.first.uri.query)).to eq("page[page]=1&page[per_page]=2")

            expect(npq_requests.count).to eq(1)
            expect(URI.decode_uri_component(npq_requests.first.uri.query)).to eq("page[page]=1&page[per_page]=2")
          end
        end

        context "when a page of results does not return JSON" do
          before do
            stub_request(:get, "#{ecf_url}#{path}")
              .with(query: { page: { page: 1, per_page: 2 } })
              .to_return(status: 200, body: { data: [1] }.to_json)
            stub_request(:get, "#{npq_url}#{path}")
              .with(query: { page: { page: 1, per_page: 2 } })
              .to_return(status: 200, body: "error")
          end

          it "treats it as if there are no more pages" do
            instance.make_requests {}

            expect(ecf_requests.count).to eq(1)
            expect(npq_requests.count).to eq(1)
          end
        end
      end
    end

    context "when using id substitution" do
      let(:options) { { id: } }
      let(:path) { "/path/:id" }

      before do
        stub_request(:get, "#{ecf_url}/path/#{resource.ecf_id}")
        stub_request(:get, "#{npq_url}/path/#{resource.ecf_id}")
      end

      context "when using an unsupported id" do
        let(:id) { "not_recognised" }
        let(:resource) { OpenStruct.new(ecf_id: "123") }

        it { expect { instance.make_requests {} }.to raise_error described_class::UnsupportedIdOption, "Unsupported id option: not_recognised" }
      end

      context "when using statement_ecf_id" do
        let(:id) { "statement_ecf_id" }
        let(:resource) { create(:statement, lead_provider:) }

        it "evaluates the id option and substitutes it into the path" do
          instance.make_requests do |_, _, formatted_path|
            expect(formatted_path).to eq("/path/#{resource.ecf_id}")
          end

          expect(requests.count).to eq(2)
        end
      end

      context "when using application_ecf_id" do
        let(:id) { "application_ecf_id" }
        let(:resource) { create(:application, lead_provider:) }

        it "evaluates the id option and substitutes it into the path" do
          instance.make_requests do |_, _, formatted_path|
            expect(formatted_path).to eq("/path/#{resource.ecf_id}")
          end

          expect(requests.count).to eq(2)
        end
      end

      context "when using declaration_ecf_id" do
        let(:id) { "declaration_ecf_id" }
        let(:resource) { create(:declaration, lead_provider:) }

        it "evaluates the id option and substitutes it into the path" do
          instance.make_requests do |_, _, formatted_path|
            expect(formatted_path).to eq("/path/#{resource.ecf_id}")
          end

          expect(requests.count).to eq(2)
        end
      end

      context "when using participant_outcome_ecf_id" do
        let(:id) { "participant_outcome_ecf_id" }
        let(:declaration) { create(:declaration, lead_provider:) }
        let(:resource) { create(:participant_outcome, declaration:).declaration.application.user }

        it "evaluates the id option and substitutes it into the path" do
          instance.make_requests do |_, _, formatted_path|
            expect(formatted_path).to eq("/path/#{resource.ecf_id}")
          end

          expect(requests.count).to eq(2)
        end
      end

      context "when using participant_ecf_id" do
        let(:id) { "participant_ecf_id" }
        let(:resource) { create(:application, :accepted, lead_provider:).user }

        it "evaluates the id option and substitutes it into the path" do
          instance.make_requests do |_, _, formatted_path|
            expect(formatted_path).to eq("/path/#{resource.ecf_id}")
          end

          expect(requests.count).to eq(2)
        end
      end

      context "when using application_ecf_id_for_accept_with_funded_place" do
        let(:id) { "application_ecf_id_for_accept_with_funded_place" }
        let(:resource) { create(:application, lead_provider:, eligible_for_funding: true) }

        it "evaluates the id option and substitutes it into the path" do
          instance.make_requests do |_, _, formatted_path|
            expect(formatted_path).to eq("/path/#{resource.ecf_id}")
          end

          expect(requests.count).to eq(2)
        end
      end

      context "when using application_ecf_id_for_accept_without_funded_place" do
        let(:id) { "application_ecf_id_for_accept_without_funded_place" }
        let(:resource) { create(:application, lead_provider:, eligible_for_funding: false) }

        it "evaluates the id option and substitutes it into the path" do
          instance.make_requests do |_, _, formatted_path|
            expect(formatted_path).to eq("/path/#{resource.ecf_id}")
          end

          expect(requests.count).to eq(2)
        end
      end

      context "when using application_ecf_id_for_reject" do
        let(:id) { "application_ecf_id_for_reject" }
        let(:resource) { create(:application, lead_provider:) }

        it "evaluates the id option and substitutes it into the path" do
          instance.make_requests do |_, _, formatted_path|
            expect(formatted_path).to eq("/path/#{resource.ecf_id}")
          end

          expect(requests.count).to eq(2)
        end
      end

      context "when using participant_ecf_id_for_create_outcome" do
        let(:id) { "participant_ecf_id_for_create_outcome" }
        let(:application) { create(:application, :accepted, lead_provider:) }
        let(:declaration) { create(:declaration, :completed, application:) }
        let(:resource) { declaration.application.user }

        it "evaluates the id option and substitutes it into the path" do
          instance.make_requests do |_, _, formatted_path|
            expect(formatted_path).to eq("/path/#{resource.ecf_id}")
          end

          expect(requests.count).to eq(2)
        end
      end

      context "when using application_ecf_id_for_change_from_funded_place" do
        let(:id) { "application_ecf_id_for_change_from_funded_place" }
        let(:resource) { create(:application, :accepted, lead_provider:, funded_place: true) }

        it "evaluates the id option and substitutes it into the path" do
          instance.make_requests do |_, _, formatted_path|
            expect(formatted_path).to eq("/path/#{resource.ecf_id}")
          end

          expect(requests.count).to eq(2)
        end
      end

      context "when using declaration_ecf_id_for_void" do
        let(:id) { "declaration_ecf_id_for_void" }
        let(:resource) { create(:declaration, :payable, lead_provider:) }

        it "evaluates the id option and substitutes it into the path" do
          instance.make_requests do |_, _, formatted_path|
            expect(formatted_path).to eq("/path/#{resource.ecf_id}")
          end

          expect(requests.count).to eq(2)
        end
      end

      context "when using declaration_ecf_id_for_clawback" do
        let(:id) { "declaration_ecf_id_for_clawback" }
        let(:resource) { create(:declaration, :paid, lead_provider:) }

        it "evaluates the id option and substitutes it into the path" do
          instance.make_requests do |_, _, formatted_path|
            expect(formatted_path).to eq("/path/#{resource.ecf_id}")
          end

          expect(requests.count).to eq(2)
        end
      end

      context "when using participant_ecf_id_for_resume" do
        let(:id) { "participant_ecf_id_for_resume" }
        let(:resource) { create(:application, :accepted, :deferred, lead_provider:).user }

        it "evaluates the id option and substitutes it into the path" do
          instance.make_requests do |_, _, formatted_path|
            expect(formatted_path).to eq("/path/#{resource.ecf_id}")
          end

          expect(requests.count).to eq(2)
        end
      end

      context "when using participant_ecf_id_for_defer" do
        let(:id) { "participant_ecf_id_for_defer" }
        let(:resource) { create(:application, :with_declaration, :accepted, :active, lead_provider:).user }

        it "evaluates the id option and substitutes it into the path" do
          instance.make_requests do |_, _, formatted_path|
            expect(formatted_path).to eq("/path/#{resource.ecf_id}")
          end

          expect(requests.count).to eq(2)
        end
      end

      context "when using participant_ecf_id_for_withdraw" do
        let(:id) { "participant_ecf_id_for_withdraw" }
        let(:resource) { create(:application, :with_declaration, :accepted, :deferred, lead_provider:).user }

        it "evaluates the id option and substitutes it into the path" do
          instance.make_requests do |_, _, formatted_path|
            expect(formatted_path).to eq("/path/#{resource.ecf_id}")
          end

          expect(requests.count).to eq(2)
        end
      end
    end

    context "when using dynamic payloads substitution" do
      describe "#post_declaration_payload" do
        it "returns a valid payload for the lead provider" do
          freeze_time do
            application = create(:application, :accepted, lead_provider:)
            payload = instance.post_declaration_payload

            expect(payload).to include({
              type: "participant-declaration",
              attributes: {
                declaration_type: :started,
                participant_id: application.user.ecf_id,
                course_identifier: application.course.identifier,
                declaration_date: 1.day.ago.rfc3339,
              },
            })
          end
        end
      end

      describe "#post_participant_outcome_payload" do
        let(:application) { create(:application, :accepted, lead_provider:) }
        let!(:declaration) { create(:declaration, :completed, application:) }
        let(:path) { "/api/v1/participants/npq/:id/outcomes" }
        let(:options) { { id: :participant_ecf_id_for_create_outcome } }

        it "returns a valid payload for the lead provider" do
          freeze_time do
            payload = instance.post_participant_outcome_payload

            expect(payload).to include({
              type: "npq-outcome-confirmation",
              attributes: {
                state: :passed,
                course_identifier: declaration.application.course.identifier,
                completion_date: 1.day.ago.rfc3339,
              },
            })
          end
        end
      end

      describe "#put_participant_resume_payload" do
        let!(:application) { create(:application, :accepted, :deferred, lead_provider:) }
        let(:path) { "/api/v1/participants/npq/:id/resume" }
        let(:options) { { id: :participant_ecf_id_for_resume } }

        it "returns a valid payload for the lead provider" do
          freeze_time do
            payload = instance.put_participant_resume_payload

            expect(payload).to include({
              type: "participant-resume",
              attributes: {
                course_identifier: application.course.identifier,
              },
            })
          end
        end
      end

      describe "#put_participant_defer_payload" do
        let!(:application) { create(:application, :with_declaration, :accepted, lead_provider:) }
        let(:path) { "/api/v1/participants/npq/:id/defer" }
        let(:options) { { id: :participant_ecf_id_for_defer } }

        it "returns a valid payload for the lead provider" do
          freeze_time do
            payload = instance.put_participant_defer_payload

            expect(payload).to include({
              type: "participant-defer",
              attributes: {
                course_identifier: application.course.identifier,
                reason: satisfy { |value| value.in?(Participants::Defer::DEFERRAL_REASONS) },
              },
            })
          end
        end
      end

      describe "#participant_ecf_id_for_withdraw" do
        let!(:application) { create(:application, :with_declaration, :accepted, lead_provider:) }
        let(:path) { "/api/v1/participants/npq/:id/withdraw" }
        let(:options) { { id: :participant_ecf_id_for_withdraw } }

        it "returns a valid payload for the lead provider" do
          freeze_time do
            payload = instance.put_participant_withdraw_payload

            expect(payload).to include({
              type: "participant-withdraw",
              attributes: {
                course_identifier: application.course.identifier,
                reason: satisfy { |value| value.in?(Participants::Withdraw::WITHDRAWAL_REASONS) },
              },
            })
          end
        end
      end
    end
  end
end
