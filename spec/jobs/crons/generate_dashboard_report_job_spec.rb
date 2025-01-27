require "rails_helper"

RSpec.describe Crons::GenerateDashboardReportJob do
  describe "#schedule" do
    it "enqueues job" do
      expect {
        described_class.schedule
      }.to have_enqueued_job
    end
  end

  describe "#perform" do
    it "persists report record" do
      expect {
        subject.perform_now
      }.to change(Report, :count).by(1)

      report = Report.find_by(identifier: "dashboard")

      expect(report.data).to be_present
    end

    context "when run more that once" do
      it "only creates one record" do
        expect {
          subject.perform_now
          subject.perform_now
        }.to change(Report, :count).by(1)
      end
    end
  end
end
