# frozen_string_literal: true

require "rails_helper"

RSpec.describe Contracts::ChangePerParticipant, type: :model do
  subject { described_class.new(statement:, contract:, per_participant:) }

  let(:statement) { create(:statement) }
  let!(:contract) { create(:contract, statement:) }

  let(:per_participant) { "1234.56" }

  describe "validations" do
    it "does not allow a blank per_participant" do
      expect(subject).to validate_presence_of(:per_participant).with_message(:blank).with_message("Enter the new amount")
    end

    it "does not allow non-numeric characters" do
      expect(subject).not_to allow_value("£1234.56").for(:per_participant).with_message("Amount must be a number, without commas, decimal points, or the £ symbol")
    end

    it "does not allow negative numbers" do
      expect(subject).not_to allow_value("-1234.56").for(:per_participant).with_message("Amount must be a positive number")
    end

    it "does not allow a nil statement" do
      expect(subject).not_to allow_value(nil).for(:statement)
    end

    it "does not allow a nil contract" do
      expect(subject).not_to allow_value(nil).for(:contract)
    end
  end

  describe "#change" do
    context "when there is a matching contract template" do
      let!(:contract_template) { create(:contract_template, per_participant:) }

      it "does not create a new contract template" do
        expect { subject.change }.not_to change(ContractTemplate, :count)
      end

      it "updates the contract template to the matching one" do
        expect { subject.change }.to change { contract.reload.contract_template }.to(contract_template)
      end
    end

    context "when there isn't a matching contract template" do
      it "creates a new contract template with the per_participant value" do
        expect { subject.change }.to change(ContractTemplate, :count).by(1)
        expect(contract.contract_template.per_participant).to eq(per_participant.to_f)
      end
    end

    context "when the per_participant value has more than 2 decimal places" do
      let(:per_participant) { "1234.5678" }

      it "rounds the per_participant value to 2 decimal places" do
        expect { subject.change }.to change(contract, :per_participant).to(1234.57)
      end
    end
  end
end
