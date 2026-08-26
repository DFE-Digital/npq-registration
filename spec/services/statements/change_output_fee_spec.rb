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

    context "when changing output_fee to be true" do
      subject { service.tap(&:validate) }

      let(:output_fee) { true }
      let(:original_output_fee) { false }

      context "when statement being changed is open" do
        context "when there is a later output statement" do
          before { create(:statement, :open, extend_from: statement) }

          it { is_expected.to be_valid }
        end

        context "when there is a paid later output statement" do
          before { create(:statement, :paid, extend_from: statement) }

          it { is_expected.to be_valid }
        end

        context "when there is not a later output" do
          it { is_expected.to be_valid }
        end
      end

      context "when statement being changed is payable" do
        let(:state) { :payable }

        context "when the allow payable flag is set" do
          before { service.allow_payable_statement_changes = true }

          it { is_expected.to be_valid }
        end

        context "when the allow payable flag is not set" do
          before { service.allow_payable_statement_changes = false }

          it { is_expected.to have_error :output_fee, :statement_is_payable, "Statement is payable and cannot be changed" }
        end
      end

      context "when statement being changed is paid" do
        let(:state) { :paid }

        it { is_expected.to have_error :output_fee, :statement_is_paid, "Statement has been paid and cannot be changed" }
      end
    end

    context "when changing output_fee to be false" do
      subject { service.tap(&:validate) }

      before { create(:declaration, :eligible, statement:) }

      let(:output_fee) { false }
      let(:original_output_fee) { true }

      context "when there is a paid later output statement" do
        before { create(:statement, :paid, extend_from: statement) }

        it { is_expected.to have_error :output_fee, :next_output_statement_required, "Later output statement does not exist" }
      end

      context "when there is suitable a later output statement" do
        before { create(:statement, :open, extend_from: statement) }

        context "when statement being changed is open" do
          it { is_expected.to be_valid }
        end

        context "when statement being changed is payable" do
          let(:state) { :payable }

          context "when the allow payable flag is set" do
            before { service.allow_payable_statement_changes = true }

            it { is_expected.to be_valid }
          end

          context "when the allow payable flag is not set" do
            before { service.allow_payable_statement_changes = false }

            it { is_expected.to have_error :output_fee, :statement_is_payable, "Statement is payable and cannot be changed" }
          end
        end

        context "when statement being changed is paid" do
          let(:state) { :paid }

          it { is_expected.to have_error :output_fee, :statement_is_paid, "Statement has been paid and cannot be changed" }
        end
      end

      context "when there is later output statement but it is payable" do
        before { create(:statement, :payable, extend_from: statement) }

        context "when the allow payable flag is set" do
          before { service.allow_payable_statement_changes = true }

          it { is_expected.to be_valid }
        end

        context "when the allow payable flag is not set" do
          before { service.allow_payable_statement_changes = false }

          it { is_expected.to have_error :output_fee, :next_output_statement_required, "Later output statement does not exist" }
        end
      end

      context "when there is not a suitable later output" do
        context "when other statements is exist but for other LPs and cohorts" do
          before do
            create(:statement, :open, extend_from: statement, cohort: create(:cohort, :next))
            create(:statement, :open, extend_from: statement, lead_provider: create(:lead_provider))
          end

          it { is_expected.to have_error :output_fee, :next_output_statement_required, "Later output statement does not exist" }
        end

        context "when there are milestones but no declarations" do
          before do
            StatementItem.delete_all
            create(:milestone, for_statement: statement)
          end

          it { is_expected.to have_error :output_fee, :next_output_statement_required, "Later output statement does not exist" }
        end

        context "when there are no declarations or milestones" do
          before { StatementItem.delete_all }

          it { is_expected.to be_valid }
        end
      end
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
                  .with(statement_id: statement.id, output_fee:)
        end
      end

      context "without change to output_fee value" do
        let(:statement) { create(:statement, output_fee:) }

        it "does not schedule a change" do
          expect(service.schedule_change).to be true

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
            .to eq("This will move 2 declarations and 0 milestones from #{later_name} onto this statement")
        end
      end

      context "without later statement" do
        it "says nothing will be moved" do
          expect(service.move_onto_hint)
            .to eq("There is no later output statement and no declarations or milestones will be moved")
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
            .to eq("This will move 2 declarations and 0 milestones from this statement to #{later_name}")
        end
      end

      context "without later statement" do
        context "with declarations" do
          before { declarations }

          it "says change is not possible" do
            expect(service.move_off_hint)
              .to eq("There are 2 declarations and 0 milestones on this statement but no suitable later statement")
          end
        end

        context "with milestones" do
          before { create :milestone, for_statement: statement }

          it "says change is not possible" do
            expect(service.move_off_hint)
              .to eq("There are 0 declarations and 1 milestones on this statement but no suitable later statement")
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
        let(:later) { create(:statement, :open, extend_from: statement) }

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
            travel_to 1.month.ago do
              create(:statement, state:, output_fee: false, for_date: Time.zone.now)
            end
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
