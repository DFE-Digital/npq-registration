require "rails_helper"

RSpec.describe Migration::ParityCheck, :in_memory_rails_cache do
  let(:endpoints_file_path) { "spec/fixtures/files/parity_check/no_endpoints.yml" }
  let(:instance) { described_class.new(endpoints_file_path:) }
  let(:enabled) { true }

  before do
    create_matching_ecf_lead_providers

    allow(Rails.application.config).to receive(:npq_separation) do
      {
        parity_check: {
          enabled:,
        },
      }
    end
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

        it "calls the client for each lead provider with the correct options" do
          client_double = instance_double(Migration::ParityCheck::Client, make_requests: nil)
          allow(Migration::ParityCheck::Client).to receive(:new) { client_double }

          run

          LeadProvider.find_each do |lead_provider|
            expect(Migration::ParityCheck::Client).to have_received(:new).with(
              lead_provider:,
              method: "get",
              path: "/api/v3/statements",
              options: { paginate: true, exclude: %w[attribute] },
            )
          end
          expect(client_double).to have_received(:make_requests).exactly(LeadProvider.count).times
        end

        it "saves response comparisons for each endpoint and lead provider" do
          client_double = instance_double(Migration::ParityCheck::Client)
          ecf_result_dpuble = { response: instance_double(HTTParty::Response, body: %({ "foo": "bar", "attribute": "excluded" }), code: 200), response_ms: 100 }
          npq_result_double = { response: instance_double(HTTParty::Response, body: "npq_response_body", code: 201), response_ms: 150 }
          allow(client_double).to receive(:make_requests).and_yield(ecf_result_dpuble, npq_result_double, "/formatted/path", 1)
          allow(Migration::ParityCheck::Client).to receive(:new) { client_double }

          expect { run }.to change(Migration::ParityCheck::ResponseComparison, :count).by(LeadProvider.count)

          expect(Migration::ParityCheck::ResponseComparison.all).to all(have_attributes({
            lead_provider: an_instance_of(LeadProvider),
            request_path: "/formatted/path",
            request_method: "get",
            ecf_response_status_code: 200,
            npq_response_status_code: 201,
            ecf_response_body: %({\n  \"foo\": \"bar\"\n}),
            npq_response_body: "npq_response_body",
            ecf_response_time_ms: 100,
            npq_response_time_ms: 150,
            page: 1,
          }))
        end
      end
    end
  end
end
