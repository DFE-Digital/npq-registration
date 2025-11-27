require "rails_helper"

RSpec.describe Contract, type: :model do
  subject { build(:contract) }

  describe "paper_trail" do
    it "enables paper trail" do
      expect(Contract.new).to be_versioned
    end
  end

  describe "relationships" do
    it { is_expected.to belong_to(:statement) }
    it { is_expected.to belong_to(:course) }
    it { is_expected.to belong_to(:contract_template) }
  end

  describe "validations" do
    let(:statement) { create(:statement, :open) }

    it { is_expected.to validate_uniqueness_of(:course_id).scoped_to(:statement_id).with_message("Can only have one contract for statement and course") }

    shared_examples_for "not allowing create/update/delete when the statement is in state" do |state|
      context "when the contract's statement is #{state}" do
        subject(:contract) { build(:contract, statement:, contract_template: create(:contract_template)) }

        context "when creating the contract with a contract template" do
          before { statement.update!(state:) }

          it "returns an error" do
            expect { subject.save! }.to raise_error(ActiveRecord::RecordInvalid)
            expect(subject.errors.first).to have_attributes(
              attribute: :contract_template,
              type: "statement_#{state}".to_sym,
              message: "Cannot set contract template when statement is #{state}",
            )
          end
        end

        context "when changing the contract template" do
          before do
            subject.save!
            statement.update!(state:)
            subject.contract_template = create(:contract_template)
          end

          it "returns an error" do
            expect(subject).to have_error(:contract_template, "statement_#{state}".to_sym, "Cannot set contract template when statement is #{state}")
          end
        end

        context "when deleting" do
          before do
            subject.save!
            statement.update!(state:)
          end

          it "returns an error" do
            expect { subject.destroy! }.to raise_error(ActiveRecord::RecordNotDestroyed)
            expect(subject.errors.first).to have_attributes(
              attribute: :base,
              type: "deleting_when_statement_#{state}".to_sym,
              message: "Cannot delete contract when statement is #{state}",
            )
            expect(Contract.exists?(subject.id)).to be true
          end
        end
      end
    end

    it_behaves_like "not allowing create/update/delete when the statement is in state", :payable
    it_behaves_like "not allowing create/update/delete when the statement is in state", :paid
  end
end
