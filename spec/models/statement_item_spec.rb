require "rails_helper"

RSpec.describe StatementItem, type: :model do
  subject { build(:statement_item) }

  describe "relationships" do
    it { is_expected.to belong_to(:statement).required }
    it { is_expected.to belong_to(:declaration).required }
  end

  describe "validations" do
    it { is_expected.to validate_uniqueness_of(:ecf_id).case_insensitive.with_message("ECF ID must be unique").allow_nil }

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
      %i[eligible payable paid awaiting_clawback clawed_back ineligible voided].each do |trait|
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

    describe ".not_eligible" do
      it "returns only not eligible records" do
        expect(described_class.not_eligible.pluck(:state).sort).to eql(%w[ineligible voided].sort)
      end
    end

    describe ".eligible" do
      it "returns only eligible records" do
        expect(described_class.eligible.pluck(:state)).to all eq("eligible")
      end
    end

    describe ".payable" do
      it "returns only payable records" do
        expect(described_class.payable.pluck(:state)).to all eq("payable")
      end
    end

    describe ".paid" do
      it "returns only paid records" do
        expect(described_class.paid.pluck(:state)).to all eq("paid")
      end
    end

    describe ".voided" do
      it "returns only voided records" do
        expect(described_class.voided.pluck(:state)).to all eq("voided")
      end
    end

    describe ".awaiting_clawback" do
      it "returns only records awaiting clawback" do
        expect(described_class.awaiting_clawback.pluck(:state)).to all eq("awaiting_clawback")
      end
    end

    describe ".clawed_back" do
      it "returns only clawed_back records" do
        expect(described_class.clawed_back.pluck(:state)).to all eq("clawed_back")
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

    describe ".mark_eligible" do
      let(:statement_item) { create(:statement_item, :payable) }

      it "transitions state to eligible" do
        expect(statement_item).to be_payable
        statement_item.mark_eligible!
        expect(statement_item).to be_eligible
      end

      context "with unsupported state" do
        let(:statement_item) { create(:statement_item, :paid) }

        it "raises error" do
          expect(statement_item).to be_paid
          expect { statement_item.mark_eligible! }.to raise_error(StateMachines::InvalidTransition)
        end
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

  describe "touch declaration when statement changes" do
    let!(:old_datetime) { 6.months.ago }
    let(:declaration) { create(:declaration, updated_at: old_datetime) }
    let(:statement_item) { create(:statement_item, declaration:) }

    context "when `statement_item` is created" do
      it "does not update declaration.updated_at" do
        freeze_time do
          expect(declaration.updated_at).to be_within(1.second).of(old_datetime)

          statement_item

          expect(declaration.updated_at).to be_within(1.second).of(old_datetime)
        end
      end
    end

    context "when `statement_item` is updated" do
      let(:statement) { create(:statement) }

      before do
        travel_to(old_datetime) do
          statement_item
          statement
        end
      end

      context "when `statement_id` is changed" do
        it "updates declaration.updated_at" do
          freeze_time do
            expect(declaration.updated_at).to be_within(1.second).of(old_datetime)
            expect(statement_item.updated_at).to be_within(1.second).of(old_datetime)

            statement_item.update!(statement:)

            expect(declaration.updated_at).to eq(Time.zone.now)
            expect(statement_item.updated_at).to eq(Time.zone.now)
          end
        end
      end

      context "when `statement_id` is not changed" do
        it "does not update declaration.updated_at" do
          freeze_time do
            expect(declaration.updated_at).to be_within(1.second).of(old_datetime)
            expect(statement_item.updated_at).to be_within(1.second).of(old_datetime)

            statement_item.update!(state: "payable")

            expect(declaration.updated_at).to be_within(1.second).of(old_datetime)
            expect(statement_item.updated_at).to eq(Time.zone.now)
          end
        end
      end
    end
  end
end
