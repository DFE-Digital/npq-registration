require "rails_helper"

RSpec.describe Applications::Reject, type: :model do
  let(:application) { create(:application, :pending) }
  let(:reason_for_rejection) { Application.reason_for_rejections[:rejected_by_provider] }
  let(:params) { { application:, reason_for_rejection: } }

  subject(:service) { described_class.new(params) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:application).with_message("The entered '#/application' is missing from your request. Check details and try again.") }
    it { is_expected.to validate_presence_of(:reason_for_rejection).with_message("The entered '#/reason_for_rejection' is missing from your request. Check details and try again.") }

    context "when the application is already rejected" do
      let(:application) { create(:application, :rejected) }

      it { is_expected.to have_error(:application, :has_already_been_rejected, "This NPQ application has already been rejected") }
    end

    context "when the application is accepted" do
      invalid_states = %w[submitted eligible payable paid]

      let(:application) { create(:application, :accepted) }
      let(:message) { I18n.t("activemodel.errors.models.applications/reject.attributes.application.cannot_reject_with_declarations") }

      before { create(:declaration, application:, state:) }

      invalid_states.each do |state|
        context "with a #{state} declaration" do
          let(:state) { state }

          it { is_expected.to have_error(:application, :cannot_reject_with_declarations, message) }
        end
      end

      Declaration.states.keys.without(invalid_states).each do |state|
        context "with a #{state} declaration" do
          let(:state) { state }

          it { is_expected.not_to have_error(:application, :cannot_reject_with_declarations, message) }
        end
      end
    end
  end

  describe ".reject" do
    it "marks the lead provider approval status as rejected" do
      expect { service.reject }.to change { application.reload.lead_provider_approval_status }.from("pending").to("rejected")
    end

    it "reloads application after action" do
      allow(service.application).to receive(:reload)
      service.reject
      expect(service.application).to have_received(:reload)
    end

    it "sets the reason for rejection" do
      expect { service.reject }.to change { application.reload.reason_for_rejection }.from(nil).to(reason_for_rejection)
    end
  end
end
