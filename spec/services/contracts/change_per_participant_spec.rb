# frozen_string_literal: true

require "rails_helper"

RSpec.describe Contracts::ChangePerParticipant, type: :model do
  subject(:service) { described_class.new(contract: future_contract, per_participant:) }

  let(:lead_provider) { create(:lead_provider) }
  let(:statement) { create(:statement, lead_provider:) }
  let(:course) { create(:course, :senior_leadership) }
  let(:last_months_statement) { create(:statement, lead_provider:, month: Time.zone.today.month - 1, year: Time.zone.today.year) }
  let!(:last_months_contract) { create(:contract, statement: last_months_statement, course:) }
  let(:this_months_statement) { create(:statement, lead_provider:, month: Time.zone.today.month, year: Time.zone.today.year) }
  let!(:this_months_contract) { create(:contract, statement: this_months_statement, course:) }
  let(:next_months_statement) { create(:statement, lead_provider:, month: Time.zone.today.month + 1, year: Time.zone.today.year) }
  let!(:next_months_contract) { create(:contract, statement: next_months_statement, course:) }
  let(:future_statement) { create(:statement, lead_provider:, month: Time.zone.today.month + 2, year: Time.zone.today.year) }
  let!(:future_contract) { create(:contract, statement: future_statement, course:) }
  let!(:contract_for_other_course) { create(:contract, statement: next_months_statement, course: create(:course, :early_headship_coaching_offer)) }
  let(:statement_in_other_cohort) { create(:statement, lead_provider:, cohort: create(:cohort, :next)) }
  let!(:contract_in_other_cohort) { create(:contract, statement: statement_in_other_cohort, course:) }
  let(:statement_for_other_provider) { create(:statement, lead_provider: create(:lead_provider), month: Time.zone.today.month + 1, year: Time.zone.today.year) }
  let!(:contract_for_other_provider) { create(:contract, statement: statement_for_other_provider, course:) }
  let(:per_participant) { "1234.56" }

  describe "validations" do
    it "does not allow a blank per_participant" do
      expect(subject).to validate_presence_of(:per_participant).with_message(:blank).with_message("Enter the new amount")
    end

    it "does not allow non-numeric characters" do
      expect(subject).not_to allow_value("£1234.56").for(:per_participant).with_message("Amount must be a number, without commas, or the £ symbol")
    end

    it "does not allow negative numbers" do
      expect(subject).not_to allow_value("-1234.56").for(:per_participant).with_message("Amount must be a positive number")
    end

    it "does not allow a nil contract" do
      expect(subject).not_to allow_value(nil).for(:contract)
    end

    context "when a statement is paid" do
      before do
        create(:statement, :paid, lead_provider:, month: Time.zone.today.month + 3, year: Time.zone.today.year)
      end

      it "does not allow changes" do
        expect(subject).not_to be_valid
        expect(subject).to have_error(:contract, :statement_paid, "The statement for this contract is already paid and cannot be changed")
      end
    end
  end

  describe "#change" do
    subject { service.change }

    context "when there is a matching contract template" do
      let!(:contract_template) { create(:contract_template, per_participant:) }

      it "does not create a new contract template" do
        expect { subject }.not_to change(ContractTemplate, :count)
      end

      it "updates the contract templates for contracts from the current on onwards" do
        subject
        expect(this_months_contract.reload.contract_template).to eq(contract_template)
        expect(next_months_contract.reload.contract_template).to eq(contract_template)
        expect(future_contract.reload.contract_template).to eq(contract_template)
      end

      it "does not update past contracts" do
        expect { subject }.not_to(change { last_months_contract.reload.contract_template })
      end

      it "does not update contracts for statements in other cohorts" do
        expect { subject }.not_to(change { contract_in_other_cohort.reload.contract_template })
      end

      it "does not update contracts for statements for other providers" do
        expect { subject }.not_to(change { contract_for_other_provider.reload.contract_template })
      end
    end

    context "when there isn't a matching contract template" do
      it "creates a new contract template with the per_participant value" do
        expect { subject }.to change(ContractTemplate, :count).by(1)
      end

      it "updates the contract templates for contracts from the current on onwards" do
        subject
        expect(this_months_contract.reload.contract_template.per_participant).to eq(per_participant.to_f)
        expect(next_months_contract.reload.contract_template.per_participant).to eq(per_participant.to_f)
        expect(future_contract.reload.contract_template.per_participant).to eq(per_participant.to_f)
      end

      it "does not update past contracts" do
        expect { subject }.not_to(change { last_months_contract.reload.contract_template })
      end

      it "does not update contracts for statements in other cohorts" do
        expect { subject }.not_to(change { contract_in_other_cohort.reload.contract_template })
      end
    end

    context "when the per_participant value has more than 2 decimal places" do
      let(:per_participant) { "1234.5678" }

      it "rounds the per_participant value to 2 decimal places" do
        expect { subject }.to change { this_months_contract.reload.contract_template.per_participant }.to(1234.57)
      end
    end
  end

  describe "#start_date" do
    before { freeze_time }

    it "returns the start date as today" do
      expect(service.start_date).to eq(Time.zone.today)
    end
  end

  describe "#end_date" do
    before { freeze_time }

    it "returns the end date as the month and year of the last statement" do
      expect(service.end_date).to eq(Date.new(future_statement.year, future_statement.month))
    end
  end
end
