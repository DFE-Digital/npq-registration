require "rails_helper"

RSpec.describe ContractTemplate, type: :model do
  subject { build(:contract_template) }

  describe "paper_trail" do
    it "enables paper trail" do
      expect(ContractTemplate.new).to be_versioned
    end
  end

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

    shared_examples_for "not allowing updates when used by a statement" do |statement_state:, attribute:|
      it { is_expected.to have_error(:base, "used_by_#{statement_state}_statement".to_sym, "Cannot update contract template used by a #{statement_state} statement") }

      it "does not save the change" do
        expect { contract_template.save! }.to raise_error(ActiveRecord::RecordInvalid)
        expect(contract_template.reload.attributes[attribute]).to eq original_value
      end
    end

    shared_examples_for "not allowing updates when used by a statement in state" do |statement_state|
      context "when the contract template is being used by a #{statement_state} statement" do
        subject(:contract_template) do
          create(:contract_template,
                 recruitment_target: original_recruitment_target,
                 per_participant: original_per_participant,
                 targeted_delivery_funding_per_participant: original_targeted_delivery_funding_per_participant,
                 special_course: original_special_course)
        end

        let(:original_recruitment_target) { 72 }
        let(:original_per_participant) { 800 }
        let(:original_targeted_delivery_funding_per_participant) { 100 }
        let(:original_special_course) { false }

        let(:contract) { create(:contract, statement:, contract_template:) }
        let(:statement) { create(:statement, :open) }

        before do
          contract
          statement.update!(state: statement_state)
        end

        context "when updating the contract template recruitment_target" do
          let(:original_value) { original_recruitment_target }

          before { contract_template.recruitment_target = 1000 }

          it_behaves_like "not allowing updates when used by a statement", statement_state:, attribute: "recruitment_target"
        end

        context "when updating the contract template per_participant" do
          let(:original_value) { original_per_participant }

          before { contract_template.per_participant = 9000 }

          it_behaves_like "not allowing updates when used by a statement", statement_state:, attribute: "per_participant"
        end

        context "when updating the contract template targeted_delivery_funding_per_participant" do
          let(:original_value) { original_targeted_delivery_funding_per_participant }

          before { contract_template.targeted_delivery_funding_per_participant = 9000 }

          it_behaves_like "not allowing updates when used by a statement", statement_state:, attribute: "targeted_delivery_funding_per_participant"
        end

        context "when updating the contract template special_course" do
          let(:original_value) { original_special_course }

          before { contract_template.special_course = true }

          it_behaves_like "not allowing updates when used by a statement", statement_state:, attribute: "special_course"
        end
      end
    end

    it_behaves_like "not allowing updates when used by a statement in state", "payable"
    it_behaves_like "not allowing updates when used by a statement in state", "paid"
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
