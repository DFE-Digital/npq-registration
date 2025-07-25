require "rails_helper"

RSpec.describe Statement, type: :model do
  subject(:statement) { create(:statement) }

  describe "relationships" do
    it { is_expected.to belong_to(:cohort).required }
    it { is_expected.to belong_to(:lead_provider).required }
    it { is_expected.to have_many(:statement_items) }
    it { is_expected.to have_many(:declarations) }
    it { is_expected.to have_many(:contracts) }
    it { is_expected.to have_many(:declarations).through(:statement_items) }
    it { is_expected.to have_many(:adjustments) }
  end

  describe "validations" do
    it { is_expected.to validate_numericality_of(:month).is_in(1..12).only_integer.with_message("Month must be a number between 1 and 12") }
    it { is_expected.to validate_numericality_of(:year).only_integer.is_in(2020..2050).with_message("Year must be a 4 digit number") }
    it { is_expected.to allow_value(%w[true false]).for(:output_fee).with_message("Output fee must be true or false") }
    it { is_expected.not_to allow_value(nil).for(:output_fee).with_message("Choose yes or no for output fee") }
    it { is_expected.to validate_uniqueness_of(:ecf_id).case_insensitive.with_message("ECF ID must be unique") }
    it { is_expected.to validate_uniqueness_of(:lead_provider_id).scoped_to(:cohort_id, :year, :month).with_message("A statement for this lead provider, cohort, year and month already exists") }

    describe "State validation" do
      context "when setting invalid state" do
        let(:statement) { build(:statement, state: "madeup") }

        it "returns error" do
          expect(statement).to be_invalid
          expect(statement.errors[:state].first).to eql("is invalid")
        end
      end
    end

    describe "payment date validation" do
      context "when the payment date is before the deadline date" do
        let(:statement) { build(:statement, payment_date: 1.day.ago, deadline_date: Time.zone.today) }

        it "returns an error" do
          expect(statement).to be_invalid
          expect(statement).to have_error(:payment_date, :invalid, "must be on or after the deadline date")
        end
      end

      context "when there is no payment date" do
        let(:statement) { build(:statement, payment_date: nil, deadline_date: Time.zone.today) }

        it "is valid" do
          expect(statement).to be_valid
        end
      end

      context "when there is no deadline date" do
        let(:statement) { build(:statement, payment_date: Time.zone.today, deadline_date: nil) }

        it "is valid" do
          expect(statement).to be_valid
        end
      end
    end
  end

  describe "scopes" do
    describe ".paid" do
      it "selects only paid statements" do
        expect(Statement.paid.to_sql).to include(%(WHERE "statements"."state" = 'paid'))
      end
    end

    describe ".unpaid" do
      it "selects only unpaid statements" do
        expect(Statement.unpaid.to_sql).to include(%(WHERE "statements"."state" IN ('open', 'payable')))
      end
    end

    describe ".with_state" do
      it "selects only statements with states matching the provided name" do
        expect(Statement.with_state("foo").to_sql).to include(%(WHERE "statements"."state" = 'foo'))
      end

      it "selects only multiple statements with states matching the provided names" do
        expect(Statement.with_state("foo", "bar").to_sql).to include(%(WHERE "statements"."state" IN ('foo', 'bar')))
      end
    end

    describe ".with_output_fee" do
      it "selects only output fee statements" do
        expect(Statement.with_output_fee.to_sql).to include(%(WHERE "statements"."output_fee" = TRUE))
      end
    end

    describe ".next_output_fee_statements" do
      let(:next_output_fee_statement_1) { create(:statement, :open, :next_output_fee, deadline_date: 5.days.from_now) }
      let(:next_output_fee_statement_2) { create(:statement, :open, :next_output_fee, deadline_date: 1.day.from_now) }
      let(:next_output_fee_statement_3) { create(:statement, :open, :next_output_fee, deadline_date: 2.days.from_now) }

      before do
        # Not output fee
        create(:statement, output_fee: false, deadline_date: 1.hour.from_now)
        # In the past
        create(:statement, output_fee: true, deadline_date: 1.day.ago)
      end

      subject { described_class.next_output_fee_statements }

      it { is_expected.to eq([next_output_fee_statement_2, next_output_fee_statement_3, next_output_fee_statement_1]) }

      context "with statements that aren't open" do
        before do
          # Paid
          create(:statement, :next_output_fee, :paid, deadline_date: 1.hour.from_now)
          # Payable
          create(:statement, :next_output_fee, :payable, deadline_date: 3.days.from_now)
        end

        it { is_expected.to eq([next_output_fee_statement_2, next_output_fee_statement_3, next_output_fee_statement_1]) }
      end
    end
  end

  describe "paper_trail" do
    subject { create(:statement, :open) }

    it "enables paper trail" do
      expect(subject).to be_versioned
    end

    it "creates a version with a note" do
      with_versioning do
        expect(PaperTrail).to be_enabled

        subject.update!(
          state: :payable,
          version_note: "This is a test",
        )
        version = subject.versions.last
        expect(version.note).to eq("This is a test")
        expect(version.object_changes["state"]).to eq(%w[open payable])
      end
    end
  end

  describe "State transition" do
    context "when from open to payable" do
      let(:statement) { create(:statement, :open) }

      it "transitions state to payable" do
        expect(statement).to be_open
        statement.mark_payable!
        expect(statement).to be_payable
      end
    end

    context "when from payable to paid" do
      let(:statement) { create(:statement, :payable, marked_as_paid_at: 1.week.ago) }

      it "transitions state to payable" do
        expect(statement).to be_payable
        statement.mark_paid!
        expect(statement).to be_paid
      end
    end

    context "when from paid to payable" do
      let(:statement) { create(:statement, :paid) }

      it "raises error" do
        expect(statement).to be_paid
        expect { statement.mark_payable! }.to raise_error(StateMachines::InvalidTransition)
      end
    end
  end

  describe "#mark_as_paid_at!" do
    it "sets marked_as_paid_at" do
      expect { subject.tap(&:mark_as_paid_at!).reload }
        .to change(subject, :marked_as_paid_at)
    end
  end

  describe "#marked_as_paid_with_date?" do
    context "with a statement marked as paid" do
      subject { create(:statement, :paid) }

      it { is_expected.to be_marked_as_paid_with_date }
    end

    context "with a statement not marked as paid" do
      it { is_expected.not_to be_marked_as_paid_with_date }
    end
  end

  describe "#allow_marking_as_paid?" do
    subject { statement.allow_marking_as_paid? }

    let(:declaration) { create(:declaration, :payable) }

    context "with payable statement with declarations" do
      let(:statement) { create(:statement, :next_output_fee, :payable, declaration:) }

      it { is_expected.to be true }
    end

    context "with non output fee statement" do
      let(:statement) { create(:statement, :payable, output_fee: false, declaration:) }

      it { is_expected.to be false }
    end

    context "with statement not in payable state" do
      let :statement do
        create(:statement, :open, :next_output_fee, declaration:,
                                                    deadline_date: Time.zone.yesterday)
      end

      it { is_expected.to be false }
    end

    context "with statement without declarations" do
      let(:statement) { create(:statement, :next_output_fee, :payable) }

      it { is_expected.to be false }
    end

    context "with future deadline date" do
      let :statement do
        create(:statement, :next_output_fee, :payable, declaration:,
                                                       deadline_date: Time.zone.today)
      end

      it { is_expected.to be false }
    end

    context "with nil deadline date" do
      let :statement do
        create(:statement, :next_output_fee, :payable, declaration:, deadline_date: nil)
      end

      it { is_expected.to be false }
    end
  end

  describe "#authorising_for_payment?" do
    subject { statement.authorising_for_payment? }

    context "with payable statement with marked_as_paid_at set" do
      let(:statement) { build(:statement, :payable, marked_as_paid_at: Time.zone.now) }

      it { is_expected.to be true }
    end

    context "with payable statement without marked_as_paid_at set" do
      let(:statement) { build(:statement, :payable, marked_as_paid_at: nil) }

      it { is_expected.to be false }
    end

    context "with paid statement with marked_as_paid_at set" do
      let(:statement) { build(:statement, :paid, marked_as_paid_at: Time.zone.now) }

      it { is_expected.to be false }
    end

    context "with open statement with marked_as_paid_at_set" do
      let(:statement) { build(:statement, :open, marked_as_paid_at: Time.zone.now) }

      it { is_expected.to be false }
    end
  end

  describe "#past?" do
    subject { statement }

    context "when the statement is in the past" do
      let(:statement) { build(:statement, month: Time.zone.today.month - 1, year: Time.zone.today.year) }

      it { is_expected.to be_past }
    end

    context "when the statement is in the current month" do
      let(:statement) { build(:statement, month: Time.zone.today.month, year: Time.zone.today.year) }

      it { is_expected.not_to be_past }
    end

    context "when the statement is in the future" do
      let(:statement) { build(:statement, month: Time.zone.today.month + 1, year: Time.zone.today.year) }

      it { is_expected.not_to be_past }
    end
  end
end
