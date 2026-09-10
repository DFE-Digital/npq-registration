require "rails_helper"

RSpec.describe Statements::ChangeOutputFee, type: :model do
  subject(:service) { described_class.new(statement:, output_fee:) }

  let(:output_fee) { true }
  let(:original_output_fee) { false }
  let(:state) { :open }

  let :statement do
    create(:statement, state:, output_fee: original_output_fee, for_date: 30.days.from_now)
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:statement) }
    it { is_expected.not_to allow_value(nil).for(:output_fee) }

    context "when the statement is in the past" do
      context "when statement is paid" do
        let(:statement) { create(:statement, :paid, for_date: 2.months.ago) }

        it { is_expected.to have_error :output_fee, :statement_is_paid, "Statement has been paid and cannot be changed" }
      end

      context "when statement is payable" do
        context "with confirmation for changing payable" do
          before { service.allow_payable_statement_changes = true }

          context "when turning output fee on" do
            let :statement do
              create(:statement, state: :payable, for_date: 2.months.ago, output_fee: false)
            end

            it { is_expected.to have_error :output_fee, :payment_date_has_passed, "Payment date has already passed so cannot be changed" }
          end

          context "when turning output fee off" do
            let :statement do
              create(:statement, state: :payable, for_date: 2.months.ago, output_fee: true)
            end

            let(:output_fee) { false }

            context "when there is a later statement" do
              before { create(:statement, :open, for_date: 1.month.from_now, output_fee: true) }

              it { is_expected.to be_valid }
            end

            context "when there isn't a later statement" do
              it { is_expected.to be_valid }

              context "and there are declarations" do
                before { create(:declaration, statement:) }

                it { is_expected.to have_error :output_fee, :next_output_statement_required, "Later payment run statement does not exist" }
              end
            end
          end
        end

        context "without confirmation for changing payable" do
          let :statement do
            create(:statement, state: :payable, for_date: 2.months.ago, output_fee: true)
          end

          it { is_expected.to have_error :allow_payable_statement_changes, :accepted, "Confirm you wish to change payable statements" }
        end
      end
    end

    context "with the current payable statement" do
      context "when turning output fee on" do
        let(:statement) { create(:statement, :payable, output_fee: false) }

        context "with confirmation of changing payable" do
          before { service.allow_payable_statement_changes = true }

          context "with later statement" do
            before { create(:statement, :open, extend_from: statement, output_fee: true) }

            it { is_expected.to be_valid }
          end

          context "without later statement" do
            it { is_expected.to be_valid }
          end
        end

        context "without confirmation of changing payable" do
          before { create(:statement, :open, extend_from: statement, output_fee: true) }

          it { is_expected.to have_error :allow_payable_statement_changes, :accepted, "Confirm you wish to change payable statements" }
        end
      end

      context "when turning output fee off" do
        let(:statement) { create(:statement, :payable, output_fee: true) }
        let(:output_fee) { false }

        context "with confirmation of changing payable" do
          before { service.allow_payable_statement_changes = true }

          context "with later statement" do
            before { create(:statement, :open, extend_from: statement, output_fee: true) }

            it { is_expected.to be_valid }
          end

          context "without later statement" do
            it { is_expected.to be_valid }

            context "with declarations" do
              before { create(:declaration, statement:) }

              it { is_expected.to have_error :output_fee, :next_output_statement_required, "Later payment run statement does not exist" }
            end
          end
        end

        context "without confirmation of changing payable" do
          before { create(:statement, :open, extend_from: statement, output_fee: true) }

          it { is_expected.to have_error :allow_payable_statement_changes, :accepted, "Confirm you wish to change payable statements" }
        end
      end
    end

    context "with open statement in the future" do
      context "when turning output fee on" do
        context "with later statement" do
          before { create(:statement, :open, extend_from: statement, output_fee: true) }

          it { is_expected.to be_valid }
        end

        context "without later statement" do
          it { is_expected.to be_valid }
        end
      end

      context "when turning output fee off" do
        let(:output_fee) { false }
        let(:original_output_fee) { true }

        context "with later statement" do
          before { create(:statement, :open, extend_from: statement, output_fee: true) }

          it { is_expected.to be_valid }
        end

        context "without later statement" do
          it { is_expected.to be_valid }

          context "with declaration" do
            before { create(:declaration, statement:) }

            it { is_expected.to have_error :output_fee, :next_output_statement_required, "Later payment run statement does not exist" }
          end
        end
      end
    end
  end

  describe ".can_change_statement?" do
    subject { described_class.can_change_statement?(statement) }

    context "with future open statement" do
      context "with output_fee true" do
        let(:statement) { build(:statement, :next_output_fee) }

        it { is_expected.to be true }
      end

      context "with output_fee false" do
        let(:statement) { build(:statement, :open, output_fee: false) }

        it { is_expected.to be true }
      end
    end

    context "with current payable statement" do
      context "with output_fee true" do
        let(:statement) { build(:statement, :payable, output_fee: true) }

        it { is_expected.to be true }
      end

      context "with output_fee false" do
        let(:statement) { build(:statement, :payable, output_fee: false) }

        it { is_expected.to be true }
      end
    end

    context "with past payable statement" do
      context "with output statement" do
        let :statement do
          build(:statement, state: :payable, for_date: 2.months.ago, output_fee: true)
        end

        it { is_expected.to be true }
      end

      context "with non-output statement" do
        let :statement do
          build(:statement, state: :payable, for_date: 2.months.ago, output_fee: false)
        end

        it { is_expected.to be false }
      end
    end

    context "with past paid statement" do
      context "with output_fee true" do
        let(:statement) { build(:statement, :paid, output_fee: true) }

        it { is_expected.to be false }
      end

      context "with output_fee false" do
        let(:statement) { build(:statement, :paid, output_fee: false) }

        it { is_expected.to be false }
      end
    end
  end

  describe "#requires_payable_override?" do
    context "with open statement" do
      let(:statement) { create :statement, :next_output_fee }

      it { is_expected.to have_attributes requires_payable_override?: false }
    end

    context "with payable statement" do
      let(:statement) { create :statement, :payable, output_fee: true }

      it { is_expected.to have_attributes requires_payable_override?: true }
    end
  end

  describe "#next_output_statement" do
    subject { service.next_output_statement }

    before { later_statement }

    context "with open statement" do
      let(:statement) { create(:statement, :next_output_fee) }

      context "without later statement" do
        let(:later_statement) { nil }

        it { is_expected.to be_nil }
      end

      context "with later non-output statement" do
        let(:later_statement) { create(:statement, extend_from: statement, output_fee: false) }

        it { is_expected.to be_nil }
      end

      context "with later statement" do
        let :later_statement do
          intermediate = create(:statement, extend_from: statement, output_fee: false)
          create(:statement, extend_from: intermediate, output_fee: true)
        end

        it { is_expected.to eq(later_statement) }
      end

      context "with later statement for another provider" do
        let :later_statement do
          create(:statement, extend_from: statement,
                             lead_provider: create(:lead_provider))
        end

        it { is_expected.to be_nil }
      end

      context "with later statement for another cohort" do
        let :later_statement do
          create(:statement, extend_from: statement,
                             cohort: create(:cohort))
        end

        it { is_expected.to be_nil }
      end

      context "with multiple later output statements" do
        let :later_statement do
          build(:statement, extend_from: statement, output_fee: true) do |later|
            # ensure the 'earlier' output statement has a earlier in the db table
            # than then later output statement
            create(:statement, extend_from: later, output_fee: true)
            later.save!
          end
        end

        it { is_expected.to eq later_statement }
      end

      context "with past statements still left open by mistake" do
        let(:statement) { create(:statement, for_date: 1.month.ago) }
        let(:later_statement) { create(:statement, :payable, extend_from: statement) }

        it { is_expected.to be_nil }
      end
    end

    context "with payable statement" do
      context "when in past" do
        let(:statement) { create(:statement, state: :payable, for_date: 2.months.ago, output_fee: true) }

        let :later_statement do
          last_month = create(:statement, :payable, extend_from: statement, output_fee: true)
          create(:statement, :payable, extend_from: last_month, output_fee: true).tap do |current_statement|
            next_open = create(:statement, :open, extend_from: current_statement, output_fee: true)
            create(:statement, :open, extend_from: next_open, output_fee: true)
          end
        end

        it { is_expected.to eq(later_statement) }
      end

      context "when current statement" do
        let(:statement) { create(:statement, :payable, output_fee: true) }

        let :later_statement do
          create(:statement, :open, extend_from: statement, output_fee: true)
        end

        it { is_expected.to eq(later_statement) }
      end

      context "without later statement" do
        let(:statement) { create(:statement, :payable, output_fee: true) }
        let(:later_statement) { nil }

        it { is_expected.to be_nil }
      end

      context "with later statement which is paid" do
        let(:statement) { create(:statement, state: "payable", for_date: 2.months.ago) }

        let :later_statement do
          create(:statement, :paid, extend_from: statement,
                                    deadline_date: 20.days.ago,
                                    payment_date: 2.days.from_now)
        end

        it { is_expected.to be_nil }
      end
    end

    context "with paid statement" do
      let :statement do
        create(:statement, :paid, for_date: 1.month.ago, output_fee: true)
      end

      let :later_statement do
        create(:statement, :paid, extend_from: statement, output_fee: true)
      end

      it { is_expected.to be_nil }
    end
  end

  describe "#schedule_change" do
    before do
      allow(Statements::ChangeOutputFeeJob).to receive(:perform_later).and_call_original
    end

    context "when valid" do
      context "with change to output_fee value" do
        it "schedules the background job to make the change" do
          expect(service.schedule_change).to be true

          expect(Statements::ChangeOutputFeeJob)
            .to have_received(:perform_later)
                  .with(statement_id: statement.id,
                        output_fee:,
                        allow_payable_statement_changes: false)
        end
      end

      context "without change to output_fee value" do
        let(:statement) { create(:statement, output_fee:) }

        it "does not schedule a change" do
          expect(service.schedule_change).to be false

          expect(Statements::ChangeOutputFeeJob).not_to have_received(:perform_later)
        end
      end
    end

    context "when invalid" do
      let :statement do
        create(:statement, :paid, output_fee: false, for_date: 20.days.ago)
      end

      it "does not schedule a change" do
        expect(service.schedule_change).to be false

        expect(Statements::ChangeOutputFeeJob).not_to have_received(:perform_later)
      end
    end
  end

  describe "declaration counts" do
    let(:later) { create(:statement, :open, extend_from: statement) }
    let(:later_name) { Date.new(later.year, later.month).to_fs(:govuk_approx) }

    describe "#move_onto_hint" do
      context "with later statement" do
        before do
          create_list(:declaration, 2, :eligible, statement: later)

          travel_to statement.deadline_date + 3.days do
            create(:declaration, :eligible, statement: later)
          end
        end

        it "includes only declarations declared before this statements deadline date" do
          expect(service.move_onto_hint)
            .to eq("This will move 2 declarations and 0 milestones from the next payment run statement, #{later_name}, onto this statement")
        end
      end

      context "without later statement" do
        it "says nothing will be moved" do
          expect(service.move_onto_hint)
            .to eq("There is no later payment run statement and no declarations or milestones will be moved")
        end
      end

      context "when output fee is being turned off" do
        let(:original_output_fee) { true }
        let(:output_fee) { false }

        it { expect(service.move_onto_hint).to be_nil }
      end
    end

    describe "#move_off_hint" do
      let(:original_output_fee) { true }
      let(:output_fee) { false }
      let(:declarations) { create_list(:declaration, 2, :eligible, statement: statement) }

      context "with later statement" do
        before { declarations && later }

        it "includes declarations count and destination statement" do
          expect(service.move_off_hint)
            .to eq("This will move 2 declarations and 0 milestones from this statement to the next Open payment run statement which is #{later_name}")
        end
      end

      context "without later statement" do
        context "with declarations" do
          before { declarations }

          it "says change is not possible" do
            expect(service.move_off_hint)
              .to eq("There are 2 declarations and 0 milestones on this statement but no suitable later payment run statement")
          end
        end

        context "with milestones" do
          before { create :milestone, for_statement: statement }

          it "says change is not possible" do
            expect(service.move_off_hint)
              .to eq("There are 0 declarations and 1 milestones on this statement but no suitable later payment run statement")
          end
        end

        context "without milestones or declarations" do
          it "allows the change" do
            expect(service.move_off_hint)
              .to eq("There are no declarations or milestones on this statement")
          end
        end
      end

      context "when output fee being turned on" do
        let(:original_output_fee) { false }
        let(:output_fee) { true }

        it { expect(service.move_off_hint).to be_nil }
      end
    end
  end

  describe "#change_statement_and_reconcile!" do
    subject(:reconcile) { service.change_statement_and_reconcile! }

    context "when turning output fee on" do
      context "when no later output fee statement" do
        it "updates output_fee" do
          expect { reconcile }
            .to change { statement.reload.output_fee }.from(false).to(true)
        end

        it "does not change statement declaration count" do
          expect { reconcile }.to(not_change { statement.declarations.count })
        end
      end

      context "with later statement" do
        let(:later) { create(:statement, :open, output_fee: true, extend_from: statement) }

        context "without declarations" do
          before { later }

          let(:milestone) { create(:milestone, for_statement: later) }

          it "updates output_fee" do
            expect { reconcile }
              .to change { statement.reload.output_fee }.from(false).to(true)
          end

          it "does not change statement declaration count" do
            expect { reconcile }.to(not_change { statement.declarations.count })
          end

          it "moves milestones" do
            expect { reconcile }
              .to change { milestone.reload.statements }.from([later]).to([statement])
          end
        end

        context "with declarations" do
          before { create_list(:declaration, 3, :eligible, statement: later) }

          it "updates output_fee" do
            expect { reconcile }
              .to change { statement.reload.output_fee }.from(false).to(true)
          end

          it "statement declaration count" do
            expect { reconcile }.to change { statement.declarations.count }.from(0).to(3)
          end

          it "changes later statement declaration count" do
            expect { reconcile }.to change { later.declarations.count }.from(3).to(0)
          end

          it "leaves declarations in eligible state" do
            expect { reconcile }
              .to(not_change { Declaration.all.pluck(:state) }
                    .and(not_change { StatementItem.all.pluck(:state) }))
          end

          context "with declaration_dates after the deadline date" do
            before do
              travel_to statement.deadline_date + 3.days do
                create(:declaration, :eligible, statement: later)
              end
            end

            it "only moves those declarations made early enough" do
              expect { reconcile }
                .to change { statement.declarations.count }.from(0).to(3)
                .and change { later.declarations.count }.from(4).to(1)
            end
          end
        end

        context "when statement is already payable" do
          before do
            service.allow_payable_statement_changes = true
            create_list(:declaration, 3, :eligible, statement: later)
          end

          let(:state) { :payable }

          it "updates output_fee" do
            expect { reconcile }
              .to change { statement.reload.output_fee }.from(false).to(true)
          end

          it "statement declaration count" do
            expect { reconcile }.to change { statement.declarations.count }.by(3)
          end

          it "changes later statement declaration count" do
            expect { reconcile }.to change { later.declarations.count }.by(-3)
          end

          it "moves eligible declarations to payable state" do
            expect { reconcile }
              .to change { Declaration.distinct.pluck(:state) }.from(%w[eligible]).to(%w[payable])
                  .and change { StatementItem.distinct.pluck(:state) }.from(%w[eligible]).to(%w[payable])
          end
        end

        context "with declarations which occurred after this statements deadline date" do
          before do
            service.allow_payable_statement_changes = true

            create_list(:declaration,
                        2,
                        :eligible,
                        statement: later,
                        declaration_date: statement.deadline_date - 1.day)

            create_list(:declaration,
                        2,
                        :eligible,
                        declaration_date: statement.deadline_date + 1.day,
                        statement: later)
          end

          let :statement do
            create(:statement, state:, output_fee: false, for_date: Time.zone.now)
          end

          it "updates output_fee" do
            expect { reconcile }
              .to change { statement.reload.output_fee }.from(false).to(true)
          end

          it "moves declarations before target statements deadline date" do
            expect { reconcile }.to change { statement.declarations.count }.from(0).to(2)
          end

          it "does not move declarations after target statements deadline date" do
            expect { reconcile }.to change { later.declarations.count }.from(4).to(2)
          end

          it "provides correct declaration movement estimate" do
            expect(service.move_onto_hint).to match("move 2 declarations")
          end
        end
      end
    end

    context "when turning output fee off" do
      let(:original_output_fee) { true }
      let(:output_fee) { false }
      let(:later) { create(:statement, :open, extend_from: statement) }

      before { later }

      context "without declarations" do
        let(:milestone) { create(:milestone, for_statement: statement) }

        it "updates output_fee" do
          expect { reconcile }
            .to change { statement.reload.output_fee }.from(true).to(false)
        end

        it "does not change statement declaration count" do
          expect { reconcile }.to(not_change { statement.declarations.count })
        end

        it "moves milestones" do
          expect { reconcile }
            .to change { milestone.reload.statements }.from([statement]).to([later])
        end
      end

      context "when statement is open and later statement is also open" do
        before { create_list(:declaration, 3, :eligible, statement:) }

        it "updates output_fee" do
          expect { reconcile }
            .to change { statement.reload.output_fee }.from(true).to(false)
        end

        it "statement declaration count" do
          expect { reconcile }.to change { statement.declarations.count }.by(-3)
        end

        it "changes later statement declaration count" do
          expect { reconcile }.to change { later.declarations.count }.by(3)
        end

        it "leaves declarations in eligible state" do
          expect { reconcile }
            .to(not_change { Declaration.all.pluck(:state) }
                  .and(not_change { StatementItem.all.pluck(:state) }))
        end
      end

      context "when statement is already payable and later statement is open" do
        before do
          service.allow_payable_statement_changes = true
          create_list(:declaration, 3, :payable, statement:)
        end

        let(:state) { :payable }

        it "updates output_fee" do
          expect { reconcile }
            .to change { statement.reload.output_fee }.from(true).to(false)
        end

        it "statement declaration count" do
          expect { reconcile }.to change { statement.declarations.count }.by(-3)
        end

        it "changes later statement declaration count" do
          expect { reconcile }.to change { later.declarations.count }.by(3)
        end

        it "changes declarations to eligible state" do
          expect { reconcile }
            .to change { Declaration.distinct.pluck(:state) }.from(%w[payable]).to(%w[eligible])
                .and change { StatementItem.distinct.pluck(:state) }.from(%w[payable]).to(%w[eligible])
        end
      end

      context "when statement is already payable and later statement is also payable" do
        before do
          service.allow_payable_statement_changes = true
          create_list(:declaration, 3, :payable, statement:)
        end

        let(:state) { :payable }
        let(:later) { create(:statement, :payable, extend_from: statement) }

        it "updates output_fee" do
          expect { reconcile }
            .to change { statement.reload.output_fee }.from(true).to(false)
        end

        it "statement declaration count" do
          expect { reconcile }.to change { statement.declarations.count }.by(-3)
        end

        it "changes later statement declaration count" do
          expect { reconcile }.to change { later.declarations.count }.by(3)
        end

        it "leaves declarations in payable state" do
          expect { reconcile }
            .to(not_change { Declaration.all.pluck(:state) }
                  .and(not_change { StatementItem.all.pluck(:state) }))
        end
      end
    end
  end
end
