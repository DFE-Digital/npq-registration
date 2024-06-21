# frozen_string_literal: true

require "rails_helper"

RSpec.describe Declarations::Void, type: :model do
  let(:statement) { create(:statement, :next_output_fee) }
  let(:declaration) { create(:declaration, lead_provider: statement.lead_provider, cohort: statement.cohort) }
  let(:instance) { described_class.new(declaration:) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:declaration) }

    context "when voiding the declaration" do
      before { declaration.update!(state: :submitted) }

      context "when the declaration is already voided" do
        before { declaration.update!(state: :voided) }

        it "adds an error to the declaration attribute" do
          expect(instance).to be_invalid
          expect(instance.errors.first).to have_attributes(attribute: :declaration, type: :already_voided)
        end
      end

      context "when the declaration is not voidable" do
        before { declaration.update!(state: :clawed_back) }

        it "adds an error to the declaration attribute" do
          expect(instance).to be_invalid
          expect(instance.errors.first).to have_attributes(attribute: :declaration, type: :not_voidable)
        end
      end
    end

    context "when clawing back the declaration" do
      before { declaration.update!(state: :paid) }

      StatementItem::REFUNDABLE_STATES.each do |ineligible_state|
        context "when the declaration already has a #{ineligible_state} statement item" do
          before { create(:statement_item, declaration:, state: ineligible_state) }

          it "adds an error to the declaration attribute" do
            expect(instance).to be_invalid
            expect(instance.errors.first).to have_attributes(attribute: :declaration, type: :not_already_refunded)
          end
        end
      end

      context "when there is no output fee statement" do
        before { statement.update!(output_fee: false) }

        it "adds an error to the declaration attribute" do
          expect(instance).to be_invalid
          expect(instance.errors.first).to have_attributes(attribute: :declaration, type: :no_output_fee_statement)
        end
      end
    end
  end

  describe "#void" do
    subject(:void) { instance.void }

    it { is_expected.to be(true) }

    Declaration::VOIDABLE_STATES.each do |declaration_state|
      context "when voiding a #{declaration_state} declaration" do
        before { declaration.update!(state: declaration_state) }

        it { expect { void }.to change { declaration.reload.state }.from(declaration_state).to("voided") }

        %w[eligible payable].each do |statement_item_state|
          context "when the declaration has a #{statement_item_state} statement item" do
            let(:statement_item) { create(:statement_item, declaration:, state: statement_item_state) }

            it { expect { void }.to change { statement_item.reload.state }.from(statement_item_state).to("voided") }
          end
        end
      end
    end

    context "when clawing back the declaration" do
      before { declaration.update!(state: :paid) }

      it { expect { void }.to change { declaration.reload.state }.from("paid").to("awaiting_clawback") }

      it "creates a statement item" do
        expect { void }.to change { statement.reload.statement_items.count }.by(1)
        created_statement_item = statement.statement_items.last
        expect(created_statement_item).to have_attributes(declaration:, state: declaration.reload.state)
      end
    end

    context "when not valid" do
      before { declaration.update!(state: :voided) }

      it { is_expected.to be(false) }
      it { expect { void }.not_to(change { declaration.reload.state }) }
    end
  end
end
