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
        it { is_expected.to have_error :output_fee, :next_output_statement_required, "Later output statement does not exist" }
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
            expect { reconcile }.to change { statement.declarations.count }.by(3)
          end

          it "changes later statement declaration count" do
            expect { reconcile }.to change { later.declarations.count }.by(-3)
          end

          it "leaves declarations in eligible state" do
            expect { reconcile }
              .to(not_change { Declaration.all.pluck(:state) }
                    .and(not_change { StatementItem.all.pluck(:state) }))
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
          it "needs to handle statements items too late for deadline"
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

  context "with unresolved thoughts" do
    it "consider allow turning output_fee off for last statement if no declarations"
  end
end
