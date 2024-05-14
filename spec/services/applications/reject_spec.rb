require "rails_helper"

RSpec.describe Applications::Reject do
  let(:application) { create(:application, :pending) }
  let(:params) { { application: } }

  subject(:service) { described_class.new(params) }

  describe "validations" do
    context "when the application is missing" do
      let(:application) { nil }

      it "is invalid and returns an error message" do
        expect(subject).to be_invalid

        expect(service.errors.messages_for(:application)).to include("The entered '#/application' is missing from your request. Check details and try again.")
      end
    end

    context "when the application is already rejected" do
      let(:application) { create(:application, :rejected) }

      it "is invalid and returns an error message" do
        expect(subject).to be_invalid

        expect(service.errors.messages_for(:application)).to include("This NPQ application has already been rejected")
      end
    end

    context "when the application is accepted" do
      let(:application) { create(:application, :accepted) }

      it "is invalid and returns an error message" do
        expect(subject).to be_invalid

        expect(service.errors.messages_for(:application)).to include("Once accepted an application cannot change state")
      end
    end
  end

  describe ".call" do
    it "marks the lead provider approval status as rejected" do
      expect { service.call }.to change { application.reload.lead_provider_approval_status }.from("pending").to("rejected")
    end
  end
end
