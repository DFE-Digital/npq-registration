require "rails_helper"

RSpec.describe ContractTemplate, type: :model do
  subject { build(:contract_template) }

  describe "relationships" do
    it { is_expected.to have_many(:contracts) }
  end

  describe "validations" do
    it { is_expected.to validate_numericality_of(:number_of_payment_periods).only_integer.is_greater_than_or_equal_to(0).with_message("Must be an integer greater than or equal to zero") }
    it { is_expected.to validate_numericality_of(:output_payment_percentage).only_integer.is_greater_than_or_equal_to(0).with_message("Must be an integer greater than or equal to zero") }
    it { is_expected.to validate_numericality_of(:service_fee_installments).only_integer.is_greater_than_or_equal_to(0).with_message("Must be an integer greater than or equal to zero") }
    it { is_expected.to validate_numericality_of(:service_fee_percentage).only_integer.is_greater_than_or_equal_to(0).with_message("Must be an integer greater than or equal to zero") }
    it { is_expected.to validate_numericality_of(:per_participant).is_greater_than(0).with_message("Must be greater than zero") }
    it { is_expected.to validate_numericality_of(:recruitment_target).only_integer.is_greater_than(0).with_message("Must be an integer greater than zero") }
    it { is_expected.to validate_uniqueness_of(:ecf_id).case_insensitive.with_message("ECF ID must be unique").allow_nil }
  end

  describe "#new_from_existing" do
    let(:contract_template) { create(:contract_template, per_participant: 123.0) }

    let(:new_contract_template) { contract_template.new_from_existing(per_participant: 321.0) }

    it "is not persisted" do
      expect(new_contract_template).not_to be_persisted
    end

    it "overrides attributes" do
      expect(new_contract_template.per_participant).to eq(321.0)
    end

    it "is copying attributes if not specified" do
      new_attributes = contract_template.new_from_existing({})
      expect(new_attributes.attributes.except("created_at", "updated_at", "id", "ecf_id")).to eq(contract_template.attributes.except("created_at", "updated_at", "id", "ecf_id"))
    end
  end

  describe "#find_from_existing" do
    subject { contract_template.find_from_existing(per_participant: 123.0) }

    let!(:contract_template) { create(:contract_template, per_participant: 123.0) }

    context "when a matching contract template exists" do
      it "returns the existing contract template" do
        expect(subject).to eq(contract_template)
      end
    end

    context "when no matching contract template exists" do
      subject { contract_template.find_from_existing(per_participant: 321.0) }

      it { is_expected.to be_nil }
    end
  end
end
