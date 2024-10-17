require "rails_helper"

RSpec.describe Migration::ParityCheck do
  let(:endpoints_file_path) { "spec/fixtures/files/parity_check/no_endpoints.yml" }
  let(:instance) { described_class.new(endpoints_file_path:) }
  let(:enabled) { true }
  let(:ecf_url) { "http://ecf.example.com" }
  let(:npq_url) { "http://npq.example.com" }

  before do
    LeadProvider.all.find_each do |lead_provider|
      create(:ecf_migration_npq_lead_provider, id: lead_provider.ecf_id)
    end

    allow(Rails.application.config).to receive(:npq_separation) do
      {
        parity_check: {
          enabled:,
          ecf_url:,
          npq_url:,
        },
      }
    end
  end

  describe(".run!") do
    subject(:run) { instance.run! }

    it "destroys existing response comparisons from previous runs" do
      existing_response_comparison = create(:response_comparison)
      run
      expect { existing_response_comparison.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    context "when the endpoints_file_path is not found" do
      let(:endpoints_file_path) { "missing.yml" }

      it { expect { run }.to raise_error(described_class::EndpointsFileNotFoundError, "Endpoints file not found: #{endpoints_file_path}") }
    end

    context "when the parity check is disabled" do
      let(:enabled) { false }

      it { expect { run }.to raise_error(described_class::UnsupportedEnvironmentError, "The parity check functionality is disabled for this environment") }
    end

    context "when there are GET endpoints" do
      let(:endpoints_file_path) { "spec/fixtures/files/parity_check/get_endpoints.yml" }
      let(:requests) { WebMock::RequestRegistry.instance.requested_signatures.hash.keys }
      let(:ecf_requests) { requests.select { |r| r.uri.host.include?("ecf") } }
      let(:npq_requests) { requests.select { |r| r.uri.host.include?("npq") } }

      before do
        stub_request(:get, "#{ecf_url}/api/v3/statements").to_return(status: 200, body: "ecf_response_body")
        stub_request(:get, "#{npq_url}/api/v3/statements").to_return(status: 201, body: "npq_response_body")
      end

      it "calls the endpoints on ECF/NPQ with correct headers for each lead provider" do
        run

        expect(ecf_requests.count).to eql(LeadProvider.count)
        expect(npq_requests.count).to eql(LeadProvider.count)

        requests.each do |request|
          expect(request.uri.path).to eq("/api/v3/statements")
          expect(request.headers["Accept"]).to eq("application/json")
          expect(request.headers["Content-Type"]).to eq("application/json")
        end
      end

      it "calls the endpoints on ECF/NPQ with valid authorization tokens for each lead provider" do
        run

        ecf_tokens = ecf_requests.map { |r| r.headers["Authorization"].partition("Bearer ").last }
        ecf_lead_providers_for_tokens = ecf_tokens.map { |token| Migration::Ecf::APIToken.find_by_unhashed_token(token).owner }
        expect(ecf_lead_providers_for_tokens).to match_array(Migration::Ecf::CpdLeadProvider.all)

        npq_tokens = npq_requests.map { |r| r.headers["Authorization"].partition("Bearer ").last }
        npq_lead_providers_for_tokens = npq_tokens.map { |token| APIToken.find_by_unhashed_token(token).lead_provider }
        expect(npq_lead_providers_for_tokens).to match_array(LeadProvider.all)
      end

      it "saves response comparisons for each endpoint and lead provider" do
        expect { run }.to change(Migration::ParityCheck::ResponseComparison, :count).by(LeadProvider.count)

        expect(Migration::ParityCheck::ResponseComparison.all).to all(have_attributes({
          lead_provider: an_instance_of(LeadProvider),
          request_path: "/api/v3/statements",
          request_method: "get",
          ecf_response_status_code: 200,
          npq_response_status_code: 201,
          ecf_response_body: "ecf_response_body",
          npq_response_body: "npq_response_body",
          ecf_response_time_ms: a_value >= 0,
          npq_response_time_ms: a_value >= 0,
        }))
      end
    end
  end
end
