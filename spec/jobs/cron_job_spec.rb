require "rails_helper"

RSpec.describe CronJob, type: :job do
  describe ".schedule" do
    before do
      described_class.cron_expression = "*/10 * * * *"
    end

    it "schedules the cron job" do
      expect {
        described_class.schedule
      }.to have_enqueued_job(described_class)
    end

    it "removes the existing job if already scheduled" do
      described_class.schedule

      expect {
        described_class.schedule
      }.not_to change(Delayed::Job, :count)
    end
  end

  context "when a job fails" do
    before do
      stub_const failing_cron_job.name, failing_cron_job
      allow(Sentry).to receive(:capture_exception)
    end

    let :failing_cron_job do
      Class.new(CronJob) do
        def self.name = "FailingCronJob"
        def perform = raise("Failing Job")
      end
    end

    let :perform_job do
      perform_enqueued_jobs do
        failing_cron_job.perform_later
      rescue RuntimeError
        nil
      end
    end

    it "makes 1 attempts" do
      expect { perform_job }.to have_performed_job.exactly(:once)
    end

    it "reports any errors" do
      perform_job

      expect(Sentry).to have_received(:capture_exception).exactly(:once)
    end
  end
end
