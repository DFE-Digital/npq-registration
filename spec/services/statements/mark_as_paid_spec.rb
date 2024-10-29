# frozen_string_literal: true

require "rails_helper"

RSpec.describe Statements::MarkAsPaid do
  subject(:service) { described_class.new(statement) }

  let(:lead_provider)        { create(:lead_provider) }
  let(:declaration)          { create(:declaration, :payable, lead_provider:) }
  let(:clawback_declaration) { create(:declaration, :awaiting_clawback, lead_provider:) }

  let :statement do
    create(:statement, statement_state, lead_provider:) do |statement|
      create(:statement_item, :payable, statement:, declaration:)
      create(:statement_item, :awaiting_clawback, statement:, declaration: clawback_declaration)
    end
  end

  describe "#mark" do
    context "with payable statement" do
      before { statement.update!(marked_as_paid_at: Time.zone.now) }

      let(:statement_state) { :payable }

      it "transitions the statement itself" do
        expect { service.mark && statement.reload }
          .to change(statement, :state).from("payable").to("paid")
      end

      describe "declarations" do
        it "transitions the payable to paid" do
          expect { service.mark && statement.reload }
            .to change(statement.declarations.payable_state, :count).from(1).to(0)
            .and change(statement.declarations.paid_state, :count).from(0).to(1)
        end

        it "transitions the awaiting_clawback to clawed_back" do
          expect { service.mark && statement.reload }
            .to change(statement.declarations.clawed_back_state, :count).from(0).to(1)
            .and change(statement.declarations.awaiting_clawback_state, :count).from(1).to(0)
        end
      end

      describe "statement items" do
        it "transitions the payable to paid" do
          expect { service.mark && statement.reload }
            .to change(statement.statement_items.payable, :count).from(1).to(0)
            .and change(statement.statement_items.paid, :count).from(0).to(1)
        end

        it "transitions the awaiting_clawback to clawed_back" do
          expect { service.mark && statement.reload }
            .to change(statement.statement_items.awaiting_clawback, :count).from(1).to(0)
            .and change(statement.statement_items.clawed_back, :count).from(0).to(1)
        end
      end

      context "with voided declaration" do
        let(:voided_declaration) { create(:declaration, :voided, lead_provider:) }

        let :statement do
          create(:statement, statement_state, lead_provider:) do |statement|
            create(:statement_item, :payable, statement:, declaration:)
            create(:statement_item, :voided, statement:, declaration: voided_declaration)
          end
        end

        it "does not transition the voided declaration" do
          expect { service.mark && statement.reload }
            .to not_change(statement.declarations.voided_state, :count)
        end

        it "does not transition the voided statement item" do
          expect { service.mark && statement.reload }
            .to not_change(statement.statement_items.voided, :count)
        end
      end
    end

    context "with paid statement" do
      let(:statement_state) { :paid }

      it { expect { service.mark }.to raise_exception(StateMachines::InvalidTransition) }
    end
  end
end
