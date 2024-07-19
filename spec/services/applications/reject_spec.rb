require "rails_helper"

RSpec.describe Applications::Reject, type: :model do
  let(:application) { create(:application, :pending) }
  let(:params) { { application: } }

  subject(:service) { described_class.new(params) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:application).with_message("The entered '#/application' is missing from your request. Check details and try again.") }

    context "when the application is already rejected" do
      let(:application) { create(:application, :rejected) }

      it { is_expected.to have_error(:application, :has_already_been_rejected, "This NPQ application has already been rejected") }
    end

    context "when the application is accepted" do
      let(:application) { create(:application, :accepted) }

      it { is_expected.to have_error(:application, :cannot_change_from_accepted, "Once accepted an application cannot change state") }
    end
  end

  describe ".reject" do
    it "marks the lead provider approval status as rejected" do
      expect { service.reject }.to change { application.reload.lead_provider_approval_status }.from("pending").to("rejected")
    end
  end
end
