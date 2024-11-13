require "rails_helper"

RSpec.describe Applications::RevertToPending do
  subject(:instance) { described_class.new(application) }

  let(:application) { create(:application, :accepted) }

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
              .to raise_exception(Applications::RevertToPending::RevertToPendingError)
              .and(not_change { application.reload.lead_provider_approval_status })
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

  describe "#call" do
    it "updates lead provider approval status" do
      expect { instance.call }
        .to change { application.reload.lead_provider_approval_status }
                   .from("accepted")
                   .to("pending")
    end
  end
end
