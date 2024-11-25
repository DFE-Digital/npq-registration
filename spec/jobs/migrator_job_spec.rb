require "rails_helper"

RSpec.describe MigratorJob, type: :job do
  let(:migrator) { Migration::Migrators::Cohort }
  let(:worker) { 0 }

  describe "#perform" do
    subject(:job) { described_class.new.perform(migrator:, worker:) }

    before { Migration::Migrators::Cohort.prepare! }

    it "runs a migrator" do
      expect(migrator).to receive(:call).with(worker:).once

      job
    end
  end

  describe "#perform_later" do
    subject(:job) { described_class.perform_later(migrator:, worker:) }

    before do
      allow(migrator).to receive(:call).and_return(true)
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
        allow(migrator).to receive(:call).and_raise(ActiveRecord::RecordInvalid)

        perform_enqueued_jobs { job }
      end

      it { expect(Sentry).to have_received(:capture_exception) }
      it { expect(Delayed::Job.count).to be_zero }
    end
  end
end
