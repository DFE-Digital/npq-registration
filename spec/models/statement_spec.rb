require "rails_helper"

RSpec.describe Statement, type: :model do
  subject(:statement) { build(:statement) }

  describe "relationships" do
    it { is_expected.to belong_to(:cohort).required }
    it { is_expected.to belong_to(:lead_provider).required }
    it { is_expected.to have_many(:statement_items) }
    it { is_expected.to have_many(:declarations) }
    it { is_expected.to have_many(:contracts) }
    it { is_expected.to have_many(:declarations).through(:statement_items) }
    it { is_expected.to have_many(:adjustments) }
    it { is_expected.to have_many(:milestone_statements) }
    it { is_expected.to have_many(:milestones).through(:milestone_statements) }
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
          expect(statement).to have_error(:state, :invalid, "is invalid")
        end
      end
    end

    describe "payment date validation" do
      context "when the payment date is before the deadline date" do
        let(:statement) { build(:statement, payment_date: 1.day.ago, deadline_date: Time.zone.today) }

        it "returns an error" do
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

    describe "output_fee validation" do
      context "when changing output_fee from true to false with milestones attached" do
        let(:statement) { create(:statement, :with_milestones, output_fee: true) }

        it "is not valid" do
          statement.output_fee = false
          expect(statement).to be_invalid
          expect(statement).to have_error(:output_fee, :has_milestones, "Cannot change output fee when statement has milestones")
        end
      end

      context "when changing an attribute other than output_fee with milestones attached" do
        let(:statement) { create(:statement, :with_milestones, output_fee: true) }

        it "is valid" do
          statement.output_fee = true
          existing_deadline_date = statement.deadline_date
          statement.deadline_date = existing_deadline_date + 1.day
          expect(statement).to be_valid
        end
      end
    end

    describe "changing reconcile_amount when the statement is payable" do
      subject(:statement) { create(:statement, :payable) }

      before { statement.reconcile_amount = 100 }

      it "returns an error" do
        expect(statement).to have_error(:base, :statement_payable, "Statement cannot be changed once it is payable")
      end
    end

    describe "changing output_fee when the statement is payable" do
      subject(:statement) { create(:statement, :payable, output_fee: true) }

      before { statement.output_fee = false }

      it { is_expected.to be_valid }
    end

    describe "changing reconcile_amount when the statement is paid" do
      subject(:statement) { create(:statement, :paid) }

      before { statement.reconcile_amount = 100 }

      it "returns an error" do
        expect(statement).to have_error(:base, :statement_paid, "Statement cannot be changed once it is paid")
      end
    end

    describe "changing output_fee when the statement is paid" do
      subject(:statement) { create(:statement, :paid, output_fee: true) }

      before { statement.output_fee = false }

      it "returns an error" do
        expect(statement).to have_error(:base, :statement_paid, "Statement cannot be changed once it is paid")
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
    subject(:statement) { build(:statement, :payable) }

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
      let(:statement) { build(:statement, for_date: 1.month.ago) }

      it { is_expected.to be_past }
    end

    context "when the statement is in the current month" do
      let(:statement) { build(:statement, for_date: Time.zone.today) }

      it { is_expected.not_to be_past }
    end

    context "when the statement is in the future" do
      let(:statement) { build(:statement, for_date: 1.month.from_now) }

      it { is_expected.not_to be_past }
    end
  end

  describe "#use_targeted_delivery_funding?" do
    subject { statement.use_targeted_delivery_funding? }

    let(:statement) { build(:statement, cohort:) }
    let(:cohort) { build(:cohort, start_year: cohort_start_year) }

    context "when the statement date is before November 2025" do
      let(:statement) { build(:statement, month: 10, year: 2025, cohort:) }

      context "when cohort start year is 2021" do
        let(:cohort_start_year) { 2021 }

        it { is_expected.to be false }
      end

      (2022..2025).each do |year|
        context "when cohort start year is #{year}" do
          let(:cohort_start_year) { year }

          it { is_expected.to be true }
        end
      end
    end

    context "when the statement date is November 2025 or later" do
      let(:statement) { build(:statement, month: 11, year: 2025, cohort:) }

      (2021..2025).each do |year|
        context "when cohort start year is #{year}" do
          let(:cohort_start_year) { year }

          it { is_expected.to be false }
        end
      end
    end
  end

  describe "#milestone_declaration_types" do
    let(:schedule_2) { create(:schedule) }
    let(:schedule_1) { create(:schedule) }
    let(:milestone_1_schedule_1) { create(:milestone, declaration_type: "started", schedule: schedule_1) }
    let(:milestone_1_schedule_2) { create(:milestone, declaration_type: "started", schedule: schedule_2) }
    let(:milestone_2_schedule_1) { create(:milestone, declaration_type: "retained-1", schedule: schedule_1) }
    let(:milestone_2_schedule_2) { create(:milestone, declaration_type: "retained-1", schedule: schedule_2) }

    subject { statement.milestone_declaration_types }

    before do
      create(:milestone_statement, milestone: milestone_1_schedule_1, statement:)
      create(:milestone_statement, milestone: milestone_1_schedule_2, statement:)
      create(:milestone_statement, milestone: milestone_2_schedule_1, statement:)
      create(:milestone_statement, milestone: milestone_2_schedule_2, statement:)
    end

    it "returns milestone declaration types associated with the statement" do
      expect(subject).to match_array(%w[started retained-1])
    end
  end
end
