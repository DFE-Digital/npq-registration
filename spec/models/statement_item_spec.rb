require "rails_helper"

RSpec.describe StatementItem, type: :model do
  describe "relationships" do
    it { is_expected.to belong_to(:statement).required }
    # it { is_expected.to belong_to(:declaration).required }
    it { is_expected.to have_many(:events).dependent(:nullify) }
  end

  describe "validations" do
    context "when setting invalid state" do
      let(:statement_item) { build(:statement_item, state: "madeup") }

      it "returns error" do
        expect(statement_item).to be_invalid
        expect(statement_item.errors[:state].first).to eql("is invalid")
      end
    end
  end

  describe "scopes" do
    before do
      %i[eligible payable paid awaiting_clawback clawed_back].each do |trait|
        create(:statement_item, trait)
      end
    end

    describe ".billable" do
      it "returns only billable records" do
        expect(described_class.billable.pluck(:state).sort).to eql(%w[eligible payable paid].sort)
      end
    end

    describe ".refundable" do
      it "returns only refundable records" do
        expect(described_class.refundable.pluck(:state).sort).to eql(%w[awaiting_clawback clawed_back].sort)
      end
    end
  end

  describe "State transition" do
    describe ".mark_payable" do
      let(:statement_item) { create(:statement_item, :eligible) }

      it "transitions state to payable" do
        expect(statement_item).to be_eligible
        statement_item.mark_payable!
        expect(statement_item).to be_payable
      end
    end

    describe ".mark_paid" do
      let(:statement_item) { create(:statement_item, :payable) }

      it "transitions state to paid" do
        expect(statement_item).to be_payable
        statement_item.mark_paid!
        expect(statement_item).to be_paid
      end
    end

    describe ".mark_voided" do
      context "when from payable" do
        let(:statement_item) { create(:statement_item, :payable) }

        it "transitions state to voided" do
          expect(statement_item).to be_payable
          statement_item.mark_voided!
          expect(statement_item).to be_voided
        end
      end

      context "when from eligible" do
        let(:statement_item) { create(:statement_item, :eligible) }

        it "transitions state to voided" do
          expect(statement_item).to be_eligible
          statement_item.mark_voided!
          expect(statement_item).to be_voided
        end
      end
    end

    describe ".mark_awaiting_clawback" do
      let(:statement_item) { create(:statement_item, :paid) }

      it "transitions state to paid" do
        expect(statement_item).to be_paid
        statement_item.mark_awaiting_clawback!
        expect(statement_item).to be_awaiting_clawback
      end
    end

    describe ".mark_clawed_back" do
      let(:statement_item) { create(:statement_item, :awaiting_clawback) }

      it "transitions state to clawed_back" do
        expect(statement_item).to be_awaiting_clawback
        statement_item.mark_clawed_back!
        expect(statement_item).to be_clawed_back
      end
    end

    describe ".mark_ineligible" do
      let(:statement_item) { create(:statement_item, :eligible) }

      it "transitions state to ineligible" do
        expect(statement_item).to be_eligible
        statement_item.mark_ineligible!
        expect(statement_item).to be_ineligible
      end
    end

    context "when from paid to payable" do
      let(:statement_item) { create(:statement_item, :paid) }

      it "raises error" do
        expect(statement_item).to be_paid
        expect { statement_item.mark_payable! }.to raise_error(StateMachines::InvalidTransition)
      end
    end
  end

  describe ".billable?" do
    %i[eligible payable paid].each do |trait|
      context "when state is #{trait}" do
        let(:statement_item) { build(:statement_item, trait) }

        it "returns true" do
          expect(statement_item).to be_billable
        end
      end
    end

    %i[awaiting_clawback clawed_back].each do |trait|
      context "when state is #{trait}" do
        let(:statement_item) { build(:statement_item, trait) }

        it "returns false" do
          expect(statement_item).not_to be_billable
        end
      end
    end
  end

  describe ".refundable?" do
    %i[awaiting_clawback clawed_back].each do |trait|
      context "when state is #{trait}" do
        let(:statement_item) { build(:statement_item, trait) }

        it "returns true" do
          expect(statement_item).to be_refundable
        end
      end
    end

    %i[eligible payable paid].each do |trait|
      context "when state is #{trait}" do
        let(:statement_item) { build(:statement_item, trait) }

        it "returns false" do
          expect(statement_item).not_to be_refundable
        end
      end
    end
  end
end
