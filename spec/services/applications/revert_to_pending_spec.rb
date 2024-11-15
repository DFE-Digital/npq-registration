require "rails_helper"

RSpec.describe Applications::RevertToPending, type: :model do
  subject(:instance) { described_class.new(application) }

  let :application do
    create(:application, :accepted) do |application|
      create(:application_state, application:)
    end
  end

  describe ".call" do
    subject(:call_service) { described_class.call(application) && application.reload }

    it "updates lead provider approval status" do
      expect { call_service }
        .to change { application.reload.lead_provider_approval_status }
                   .from("accepted")
                   .to("pending")
    end

    it "empties the funded_place attribute" do
      expect { call_service }
        .to change { application.reload.funded_place }
                   .from(false)
                   .to(nil)
    end

    it "removes Application states" do
      expect { call_service }
        .to change { application.application_states.count }
                   .from(1)
                   .to(0)
    end

    context "when already pending" do
      let(:application) { create(:application, :pending) }

      it "succeeds but does not change the approval status" do
        expect { call_service }
          .to not_change(application, :lead_provider_approval_status)
      end
    end

    context "when Application already has declarations" do
      %i[submitted voided ineligible].each do |declaration_state|
        context "with #{declaration_state} state" do
          let(:application) { create(:declaration, declaration_state).application }

          it "raises an exception" do
            expect { call_service }
              .to not_change { application.reload.lead_provider_approval_status }
              .and(not_change { application.declarations.count })
          end
        end
      end

      %i[eligible payable paid awaiting_clawback clawed_back].each do |declaration_state|
        context "with #{declaration_state} state" do
          let(:application) { create(:declaration, declaration_state).application }

          it "updates the state" do
            expect { call_service }
              .to change { application.reload.lead_provider_approval_status }
                  .from("accepted")
                  .to("pending")
              .and change { application.declarations.count }.to(0)
          end
        end
      end
    end
  end

  describe "#valid?" do
    it { is_expected.to validate_inclusion_of(:change_status_to_pending).in_array(%w[yes]) }

    context "with lead_provider_approval_status attribute" do
      subject { instance.tap(&:valid?).errors.messages[:lead_provider_approval_status] }

      context "with accepted application" do
        it { is_expected.to be_empty }
      end

      context "with pending application" do
        let(:application) { create(:application, :pending) }

        it { is_expected.not_to be_empty }
      end
    end

    context "with declarations" do
      subject { instance.tap(&:valid?).errors.full_messages }

      context "when they prevent reverting to pending" do
        before { create(:declaration, :submitted, application:) }

        it { is_expected.to include(/cannot revert/i) }
      end

      context "when they do not prevent reverting to pending" do
        before { create(:declaration, :eligible, application:) }

        it { is_expected.not_to include(/cannot revert/i) }
      end
    end
  end

  describe "#save" do
    subject(:instance) { described_class.new(application, change_status_to_pending:) }

    context "with valid form" do
      let(:change_status_to_pending) { "yes" }

      it "updates lead provider approval status" do
        expect { instance.save }
          .to change { application.reload.lead_provider_approval_status }
                     .from("accepted")
                     .to("pending")
      end
    end

    context "with invalid form" do
      let(:change_status_to_pending) { "no" }

      it "does not update the lead provider approval status" do
        expect { instance.save }
          .to(not_change { application.reload.lead_provider_approval_status })
      end
    end
  end
end
