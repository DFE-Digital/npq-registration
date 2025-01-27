require "rails_helper"

RSpec.describe Applications::RevertToPending, type: :model do
  subject(:instance) { described_class.new(application:) }

  let :application do
    create(:application, :accepted) do |application|
      create(:application_state, application:)
    end
  end

  describe "#valid?" do
    it { is_expected.to validate_inclusion_of(:change_status_to_pending).in_array(%w[yes no]) }

    context "with lead_provider_approval_status attribute" do
      subject { instance.tap(&:valid?).errors.messages[:lead_provider_approval_status] }

      context "with accepted application" do
        it { is_expected.to be_empty }
      end

      context "with rejected application" do
        let(:application) { create(:application, :rejected) }

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
        before { create(:declaration, :eligible, application:) }

        it { is_expected.to include(/already declarations/i) }
      end

      context "when they do not prevent reverting to pending" do
        before { create(:declaration, :ineligible, application:) }

        it { is_expected.not_to include(/already declarations/i) }
      end
    end
  end

  describe "#revert" do
    subject(:instance) { described_class.new(application:, change_status_to_pending:) }

    let(:change_status_to_pending) { "yes" }

    context "when valid" do
      it "returns true" do
        expect(instance.revert).to be true
      end

      it "updates lead provider approval status" do
        expect { instance.revert }
          .to change { application.reload.lead_provider_approval_status }
                     .from("accepted")
                     .to("pending")
      end

      it "empties the funded_place attribute" do
        expect { instance.revert }
          .to change { application.reload.funded_place }
                     .from(false)
                     .to(nil)
      end

      it "removes Application states" do
        expect { instance.revert }
          .to change { application.application_states.count }
                     .from(1)
                     .to(0)
      end
    end

    context "when status set to no" do
      let :application do
        create(:application, :accepted, funded_place: true).tap do |application|
          create(:declaration, :voided, application:)
          create(:application_state, application:)
        end
      end

      let(:change_status_to_pending) { "no" }

      it "returns true" do
        expect(instance.revert).to be true
      end

      it "succeeds but does not change the attributes" do
        expect { instance.revert }
          .to not_change { application.reload.lead_provider_approval_status }
              .and not_change(application, :funded_place)
      end

      it "succeeds but does not remove application_states" do
        expect { instance.revert }
          .to not_change(application.application_states, :count)
      end

      it "succeeds but does not remove declarations" do
        expect { instance.revert }
          .to not_change(application.declarations, :count)
      end
    end

    context "when already pending" do
      let :application do
        create(:application, :pending, funded_place: true).tap do |application|
          create(:declaration, :voided, application:)
          create(:application_state, application:)
        end
      end

      it "returns false" do
        expect(instance.revert).to be false
      end

      it "succeeds but does not change the attributes" do
        expect { instance.revert }
          .to not_change { application.reload.lead_provider_approval_status }
              .and not_change(application, :funded_place)
      end

      it "succeeds but does not remove application_states" do
        expect { instance.revert }
          .to not_change(application.application_states, :count)
      end

      it "succeeds but does not remove declarations" do
        expect { instance.revert }
          .to not_change(application.declarations, :count)
      end
    end

    context "when application already has declarations" do
      Applications::RevertToPending::REVERTABLE_DECLARATION_STATES.each do |declaration_state|
        context "with a revertable state: #{declaration_state}" do
          let(:application) { create(:declaration, declaration_state).application }

          it "returns true" do
            expect(instance.revert).to be true
          end

          it "updates the state" do
            expect { instance.revert }
              .to change { application.reload.lead_provider_approval_status }
                  .from("accepted")
                  .to("pending")
              .and(not_change { application.declarations.count })
          end
        end
      end

      Declaration.states.keys.excluding(Applications::RevertToPending::REVERTABLE_DECLARATION_STATES).each do |declaration_state|
        context "with a state that cannot be reverted: #{declaration_state}" do
          let(:application) { create(:declaration, declaration_state).application }

          it "returns false" do
            expect(instance.revert).to be false
          end

          it "does not change the lead provider approval status" do
            expect { instance.revert }
              .to not_change { application.reload.lead_provider_approval_status }
              .and(not_change { application.declarations.count })
          end
        end
      end
    end
  end
end
