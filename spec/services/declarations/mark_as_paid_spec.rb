# frozen_string_literal: true

require "rails_helper"

RSpec.describe Declarations::MarkAsPaid do
  subject(:service) { described_class.new(statement) }

  let(:statement) { create(:statement, deadline_date: 3.days.ago) }

  let :declaration do
    travel_to statement.deadline_date do
      create(:declaration, declaration_state, lead_provider: statement.lead_provider).tap do |declaration|
        create(:statement_item, declaration_state, declaration:, statement:)
      end
    end
  end

  let :another_declaration_statement_item do
    travel_to statement.deadline_date do
      declaration = create(:declaration, :payable, lead_provider: statement.lead_provider)
      create(:statement_item, :payable, declaration:, statement:)
    end
  end

  describe "#mark" do
    context "when the participant declaration is payable" do
      let(:declaration_state) { :payable }

      it "transitions the declaration to paid" do
        expect { service.mark(declaration) && declaration.reload }
          .to change(declaration, :state).from("payable").to("paid")
          .and change(declaration.statement_items.payable, :count).from(1).to(0)
          .and change(declaration.statement_items.paid, :count).from(0).to(1)
      end

      it "does not transition the statement item against the other declaration" do
        expect { service.mark(declaration) && declaration.reload }
          .to not_change(another_declaration_statement_item, :state)
      end
    end

    context "when the participant declaration is eligible" do
      let(:declaration_state) { :eligible }

      it "does not transition the declaration to paid" do
        expect { service.mark(declaration) && declaration.reload }
          .to raise_exception(StateMachines::InvalidTransition)
          .and not_change(declaration, :state)
          .and not_change(declaration.statement_items.eligible, :count)
      end
    end

    context "when the participant declaration is awaiting_clawback" do
      before { create(:statement_item, :paid, declaration:, statement:) }

      let(:declaration_state) { :awaiting_clawback }

      it "does not transition the declaration to paid" do
        expect { service.mark(declaration) && declaration.reload }
          .to raise_exception(StateMachines::InvalidTransition)
          .and not_change(declaration, :state)
          .and not_change(declaration.statement_items.paid, :count)
          .and not_change(declaration.statement_items.awaiting_clawback, :count)
      end
    end

    context "when the participant declaration is clawed_back" do
      before { create(:statement_item, :paid, declaration:, statement:) }

      let(:declaration_state) { :clawed_back }

      it "does not transition the declaration to paid" do
        expect { service.mark(declaration) && declaration.reload }
          .to raise_exception(StateMachines::InvalidTransition)
          .and not_change(declaration, :state)
          .and not_change(declaration.statement_items.paid, :count)
          .and not_change(declaration.statement_items.awaiting_clawback, :count)
      end
    end
  end
end
