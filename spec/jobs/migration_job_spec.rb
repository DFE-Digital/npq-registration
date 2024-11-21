require "rails_helper"

RSpec.describe MigrationJob do
  let(:coordinator_double) { instance_double(Migration::Coordinator, migrate!: nil) }

  before { allow(Migration::Coordinator).to receive(:new).and_return(coordinator_double) }

  describe "#perform" do
    subject(:job) { described_class.new.perform }

    it "triggers a migration" do
      job

      expect(coordinator_double).to have_received(:migrate!).once
    end
  end

  describe "#perform_later" do
    subject(:job) { described_class.perform_later }

    before do
      allow(coordinator_double).to receive(:migrate!).and_return(true)
      allow(Rails.logger).to receive(:warn)
      allow(Sentry).to receive(:capture_exception).and_return(true)
    end

    it "enqueues the job exactly once" do
      expect { job }.to have_enqueued_job(described_class).exactly(:once).on_queue("migration")
    end

    context "with valid job" do
      before do
        perform_enqueued_jobs { job }
      end

      it { expect(Sentry).not_to have_received(:capture_exception) }
      it { expect(Delayed::Job.count).to be_zero }
    end

    context "with invalid job" do
      before do
        allow(coordinator_double).to receive(:migrate!).and_raise(ActiveRecord::RecordInvalid)

        perform_enqueued_jobs { job }
      end

      it { expect(Sentry).to have_received(:capture_exception) }
      it { expect(Delayed::Job.count).to be_zero }
    end
  end
end
