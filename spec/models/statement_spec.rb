require "rails_helper"

RSpec.describe Statement, type: :model do
  subject(:statement) { build(:statement) }

  describe "relationships" do
    it { is_expected.to belong_to(:cohort).required }
    it { is_expected.to belong_to(:lead_provider).required }
    it { is_expected.to have_many(:statement_items) }
  end

  describe "validations" do
    it { is_expected.to validate_numericality_of(:month).is_in(1..12).only_integer.with_message("Month must be a number between 1 and 12") }
    it { is_expected.to validate_numericality_of(:year).only_integer.is_in(2020..2050) }
    it { is_expected.to allow_value(%w[true false]).for(:output_fee) }
    it { is_expected.not_to allow_value(nil).for(:output_fee) }
    it { is_expected.to validate_presence_of(:ecf_id) }
    it { is_expected.to validate_uniqueness_of(:ecf_id).case_insensitive }

    describe "Validation for statement items count" do
      context "when the statement has two or fewer statement items" do
        it "is valid" do
          create_list(:statement_item, 2, statement:)
          expect(statement.valid?).to be true
        end
      end

      context "when the statement has more than two statement items" do
        it "is not valid" do
          create_list(:statement_item, 3, statement:)

          expect(statement.valid?).to be false
          expect(statement.errors[:statement_items]).to include("cannot have more than two items")
        end
      end
    end

    describe "State validation" do
      context "when setting invalid state" do
        let(:statement) { build(:statement, state: "madeup") }

        it "returns error" do
          expect(statement).to be_invalid
          expect(statement.errors[:state].first).to eql("is invalid")
        end
      end
    end
  end

  describe "scopes" do
    describe "paid" do
      it "selects only paid statements" do
        expect(Statement.paid.to_sql).to include(%(WHERE "statements"."state" = 'paid'))
      end
    end

    describe "unpaid" do
      it "selects only unpaid statements" do
        expect(Statement.unpaid.to_sql).to include(%(WHERE "statements"."state" IN ('open', 'payable')))
      end
    end
  end

  describe "State transition" do
    context "when from open to payable" do
      let(:statement) { create(:statement, state: "open") }

      it "transitions state to payable" do
        expect(statement).to be_open
        statement.mark_payable!
        expect(statement).to be_payable
      end
    end

    context "when from payable to paid" do
      let(:statement) { create(:statement, state: "payable") }

      it "transitions state to payable" do
        expect(statement).to be_payable
        statement.mark_paid!
        expect(statement).to be_paid
      end
    end

    context "when from paid to payable" do
      let(:statement) { create(:statement, state: "paid") }

      it "raises error" do
        expect(statement).to be_paid
        expect { statement.mark_payable! }.to raise_error(StateMachines::InvalidTransition)
      end
    end
  end
end
