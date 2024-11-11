require "rails_helper"

RSpec.describe Applications::RevertToPending do
  subject(:instance) { described_class.new(application) }

  let(:application) { create(:application, :accepted) }

  describe ".call" do
    subject(:call_service) { described_class.call(application) && application.reload }

    it "updates lead provider approval status" do
      expect { call_service }
        .to change(application, :lead_provider_approval_status).from("accepted").to("pending")
    end
  end

  describe "#call" do
    it "updates lead provider approval status" do
      expect { instance.call && application.reload }
        .to change(application, :lead_provider_approval_status).from("accepted").to("pending")
    end
  end
end
