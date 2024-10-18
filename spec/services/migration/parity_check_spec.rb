require "rails_helper"

RSpec.describe Migration::ParityCheck, :in_memory_rails_cache do
  let(:endpoints_file_path) { "spec/fixtures/files/parity_check/no_endpoints.yml" }
  let(:instance) { described_class.new(endpoints_file_path:) }
  let(:enabled) { true }
  let(:ecf_url) { "http://ecf.example.com" }
  let(:npq_url) { "http://npq.example.com" }
  let(:keys) do
    LeadProvider.all.each_with_object({}) do |lead_provider, hash|
      hash[lead_provider.ecf_id] = SecureRandom.uuid
    end
  end

  before do
    create_matching_ecf_lead_providers

    allow(Rails.application.config).to receive(:npq_separation) do
      {
        parity_check: {
          enabled:,
          ecf_url:,
          npq_url:,
        },
      }
    end

    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("PARITY_CHECK_KEYS").and_return(keys.to_json)
  end

  describe ".prepare!" do
    subject(:prepare) { described_class.prepare! }

    it "destroys existing response comparisons from previous runs" do
      existing_response_comparison = create(:response_comparison)

      prepare

      expect { existing_response_comparison.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "resets the started/completed timestamps" do
      travel_to(5.days.ago) do
        described_class.prepare!
        instance.run!
      end

      prepare

      expect(described_class.started_at).to be_within(5.seconds).of(Time.zone.now)
      expect(described_class.completed_at).to be_nil
    end
  end

  describe ".running?" do
    it "returns false when the parity check has not been started" do
      expect(described_class).not_to be_running
    end

    it "returns true when the parity check has been started" do
      described_class.prepare!
      expect(described_class).to be_running
    end

    it "returns false when a partiy check has completed" do
      described_class.prepare!
      instance.run!
      expect(described_class).not_to be_running
    end
  end

  describe ".completed?" do
    it "returns false when the parity check has not been started" do
      expect(described_class).not_to be_completed
    end

    it "returns false when the parity check is running" do
      described_class.prepare!
      expect(described_class).not_to be_completed
    end

    it "returns true when a partiy check has completed" do
      described_class.prepare!
      instance.run!
      expect(described_class).to be_completed
    end
  end

  describe ".started_at" do
    it "returns the started timestamp" do
      described_class.prepare!
      expect(described_class.started_at).to be_within(5.seconds).of(Time.zone.now)
    end
  end

  describe ".completed_at" do
    it "returns the completed timestamp" do
      described_class.prepare!
      travel_to(1.day.from_now) do
        instance.run!
        expect(described_class.completed_at).to be_within(5.seconds).of(Time.zone.now)
      end
    end
  end

  describe "#run!" do
    subject(:run) { instance.run! }

    it { expect { run }.to raise_error(described_class::NotPreparedError, "You must call prepare! before running the parity check") }

    context "when prepared" do
      before { described_class.prepare! }

      it "sets the completed timestamp" do
        run

        expect(described_class.completed_at).to be_within(5.seconds).of(Time.zone.now)
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
          expect(ecf_tokens).to match_array(keys.values)

          npq_tokens = npq_requests.map { |r| r.headers["Authorization"].partition("Bearer ").last }
          expect(npq_tokens).to match_array(keys.values)
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
end
