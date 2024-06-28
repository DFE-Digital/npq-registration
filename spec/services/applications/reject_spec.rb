require "rails_helper"

RSpec.describe Applications::Reject do
  let(:application) { create(:application, :pending) }
  let(:params) { { application: } }

  subject(:service) { described_class.new(params) }

  describe "validations" do
    context "when the application is missing" do
      let(:application) { nil }

      it "is invalid and returns an error message" do
        expect(service).to be_invalid
        expect(service.errors.first).to have_attributes(attribute: :application, type: :blank)
      end
    end

    context "when the application is already rejected" do
      let(:application) { create(:application, :rejected) }

      it "is invalid and returns an error message" do
        expect(service).to be_invalid
        expect(service.errors.first).to have_attributes(attribute: :application, type: :has_already_been_rejected)
      end
    end

    context "when the application is accepted" do
      let(:application) { create(:application, :accepted) }

      it "is invalid and returns an error message" do
        expect(service).to be_invalid
        expect(service.errors.first).to have_attributes(attribute: :application, type: :cannot_change_from_accepted)
      end
    end
  end

  describe ".reject" do
    it "marks the lead provider approval status as rejected" do
      expect { service.reject }.to change { application.reload.lead_provider_approval_status }.from("pending").to("rejected")
    end
  end
end
