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

  describe "#make_requests" do
    let(:requests) { WebMock::RequestRegistry.instance.requested_signatures.hash.keys }
    let(:ecf_requests) { requests.select { |r| r.uri.host.include?("ecf") } }
    let(:npq_requests) { requests.select { |r| r.uri.host.include?("npq") } }

    context "when making a GET request" do
      let(:method) { :get }

      before do
        stub_request(:get, "#{ecf_url}#{path}").to_return(status: 200, body: "ecf_response_body")
        stub_request(:get, "#{npq_url}#{path}").to_return(status: 201, body: "npq_response_body")
      end

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

      context "when using id substitution" do
        let(:options) { { id: "lead_provider.statements.pluck(:ecf_id).sample" } }
        let(:path) { "/api/v3/statements/:id" }

        it "evaluates the id option and substitutes it into the path" do
          statement = create(:statement, lead_provider:)

          stub_request(:get, "#{ecf_url}/api/v3/statements/#{statement.ecf_id}")
          stub_request(:get, "#{npq_url}/api/v3/statements/#{statement.ecf_id}")

          instance.make_requests do |_, _, formatted_path|
            expect(formatted_path).to eq("/api/v3/statements/#{statement.ecf_id}")
          end

          expect(requests.count).to eq(2)
        end
      end

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
  end
end
