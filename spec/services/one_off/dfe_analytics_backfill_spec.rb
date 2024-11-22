require "rails_helper"

RSpec.describe OneOff::DfeAnalyticsBackfill do
  let(:senco_in_role)    { "yes" }
  let(:senco_start_date) { "2024-01-23" }
  let(:trn)              { "1234567" }

  let(:raw_application_data) do
    {
      "senco_in_role" => senco_in_role,
      "senco_start_date" => senco_start_date,
      "trn" => trn,
    }
  end

  let(:application) do
    create(:application, raw_application_data:)
  end

  context "when service is being runned" do
    before { application }

    it "backfills senco_in_role" do
      expect { OneOff::DfeAnalyticsBackfill.call }.to change { application.reload.senco_in_role }.from(nil).to(senco_in_role)
    end

    it "backfills senco_start_date" do
      expect { OneOff::DfeAnalyticsBackfill.call }.to change { application.reload.senco_start_date }.from(nil).to(Date.parse(senco_start_date))
    end

    it "backfills trn" do
      expect { OneOff::DfeAnalyticsBackfill.call }.to change { application.reload.on_submission_trn }.from(nil).to(trn)
    end
  end
end
