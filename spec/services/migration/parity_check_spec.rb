require "rails_helper"

RSpec.describe Migration::ParityCheck, :in_memory_rails_cache do
  let(:endpoints_file_path) { "spec/fixtures/files/parity_check/no_endpoints.yml" }
  let(:instance) { described_class.new(endpoints_file_path:) }
  let(:enabled) { true }

  before do
    ActiveJob::Base.queue_adapter = :test

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
      Rails.cache.write(:parity_check_completed_at, 1.day.ago)
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
      Rails.cache.write(:parity_check_completed_at, 1.day.ago)
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
      Rails.cache.write(:parity_check_completed_at, 1.day.ago)
      expect(described_class.completed_at).to be_within(5.seconds).of(1.day.ago)
    end
  end

  describe ".finalise!" do
    let(:job_args) { { lead_provider: create(:lead_provider), method: "get", path: "/path", options: {} } }

    before { ActiveJob::Base.queue_adapter = :delayed_job }

    it "sets the completed timestamp when there are no queued jobs and exactly one in-progress job" do
      ParityCheckComparisonJob.perform_later(**job_args)
      Delayed::Job.last.update!(locked_at: Time.zone.now)

      described_class.finalise!

      expect(described_class).to be_completed
    end

    it "does not set the completed timestamp when there are queued jobs and exactly one in-progress jobs" do
      ParityCheckComparisonJob.perform_later(**job_args)
      ParityCheckComparisonJob.perform_later(**job_args)
      Delayed::Job.last.update!(locked_at: Time.zone.now)

      described_class.finalise!

      expect(described_class).not_to be_completed
    end

    it "does not set the completed timestamp when there are no queued jobs and more than one in-progress jobs" do
      ParityCheckComparisonJob.perform_later(**job_args)
      ParityCheckComparisonJob.perform_later(**job_args)
      Delayed::Job.update!(locked_at: Time.zone.now)

      described_class.finalise!

      expect(described_class).not_to be_completed
    end

    it "does not set the completed timestamp when there are queued jobs and no in-progress jobs" do
      ParityCheckComparisonJob.perform_later(**job_args)

      described_class.finalise!

      expect(described_class).not_to be_completed
    end
  end

  describe ".progress" do
    let(:job_args) { { lead_provider: create(:lead_provider), method: "get", path: "/path", options: {} } }

    before { ActiveJob::Base.queue_adapter = :delayed_job }

    it "returns the percentage of completed jobs" do
      Rails.cache.write(:parity_check_job_count, 15)
      ParityCheckComparisonJob.perform_later(**job_args)
      ParityCheckComparisonJob.perform_later(**job_args)
      Delayed::Job.last.update!(locked_at: Time.zone.now)

      expect(described_class.progress).to eq(86.7)
    end

    it "returns 100 when all jobs have been completed" do
      Rails.cache.write(:parity_check_job_count, 15)
      expect(described_class.progress).to eq(100)
    end

    it "returns 0 when no jobs have been completed" do
      Rails.cache.write(:parity_check_job_count, 15)
      15.times { ParityCheckComparisonJob.perform_later(**job_args) }
      expect(described_class.progress).to eq(0)
    end

    it "returns 100 when the job count is 0" do
      Rails.cache.write(:parity_check_job_count, 0)
      expect(described_class.progress).to eq(100)
    end

    it "returns 0 when the job count is not set" do
      expect(described_class.progress).to eq(0)
    end
  end

  describe "#run!" do
    subject(:run) { instance.run! }

    it { expect { run }.to raise_error(described_class::NotPreparedError, "You must call prepare! before running the parity check") }

    context "when prepared" do
      before { described_class.prepare! }

      context "when the endpoints_file_path is not found" do
        let(:endpoints_file_path) { "missing.yml" }

        it { expect { run }.to raise_error(described_class::EndpointsFileNotFoundError, "Endpoints file not found: #{endpoints_file_path}") }
      end

      context "when the parity check is disabled" do
        let(:enabled) { false }

        it { expect { run }.to raise_error(described_class::UnsupportedEnvironmentError, "The parity check functionality is disabled for this environment") }
      end

      context "when there are multiple endpoints" do
        let(:endpoints_file_path) { "spec/fixtures/files/parity_check/multiple_endpoints.yml" }

        it "stores the total job count" do
          run

          expect(Rails.cache.read(:parity_check_job_count)).to eq(5 * LeadProvider.count)
        end
      end

      context "when there are GET endpoints" do
        let(:endpoints_file_path) { "spec/fixtures/files/parity_check/get_endpoints.yml" }

        it "queues a comparison job for each lead provider with the correct options" do
          expect { run }.to have_enqueued_job(ParityCheckComparisonJob).exactly(LeadProvider.count).times

          method = "get"
          path = "/api/v3/statements"
          options = { paginate: true, exclude: %w[attribute] }

          LeadProvider.find_each do |lead_provider|
            expect(ParityCheckComparisonJob).to have_been_enqueued.with(
              lead_provider:,
              method:,
              path:,
              options:,
            )
          end
        end
      end

      context "when there are POST endpoints" do
        let(:endpoints_file_path) { "spec/fixtures/files/parity_check/post_endpoints.yml" }

        it "queues a comparison job for each lead provider with the correct options" do
          expect { run }.to have_enqueued_job(ParityCheckComparisonJob).exactly(LeadProvider.count).times

          method = "post"
          path = "/api/v1/npq-applications/:id/accept"
          options = { id: "application_ecf_id_for_accept_with_funded_place", payload: { type: "npq-application-accept", attributes: { funded_place: true } } }

          LeadProvider.find_each do |lead_provider|
            expect(ParityCheckComparisonJob).to have_been_enqueued.with(
              lead_provider:,
              method:,
              path:,
              options:,
            )
          end
        end
      end

      context "when there are PUT endpoints" do
        let(:endpoints_file_path) { "spec/fixtures/files/parity_check/put_endpoints.yml" }

        it "queues a comparison job for each lead provider with the correct options" do
          expect { run }.to have_enqueued_job(ParityCheckComparisonJob).exactly(LeadProvider.count).times

          method = "put"
          path = "/api/v1/npq-applications/:id/change-funded-place"
          options = { id: "application_ecf_id_for_change_to_funded_place", payload: { type: "npq-application-change-funded-place", attributes: { funded_place: true } } }

          LeadProvider.find_each do |lead_provider|
            expect(ParityCheckComparisonJob).to have_been_enqueued.with(
              lead_provider:,
              method:,
              path:,
              options:,
            )
          end
        end
      end
    end
  end
end
