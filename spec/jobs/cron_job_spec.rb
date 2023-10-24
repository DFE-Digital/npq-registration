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
      }.to change(Delayed::Job, :count).by(0)
    end
  end
end

