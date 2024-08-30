require "rails_helper"

RSpec.describe ContractTemplate, type: :model do
  subject { build(:contract_template) }

  # describe "relationships" do
  #   it { is_expected.to have_many(:contracts) }
  # end

  describe "validations" do
    it { is_expected.to validate_numericality_of(:number_of_payment_periods).only_integer.is_greater_than_or_equal_to(0).with_message("Must be an integer greater than or equal to zero") }
    it { is_expected.to validate_numericality_of(:output_payment_percentage).only_integer.is_greater_than_or_equal_to(0).with_message("Must be an integer greater than or equal to zero") }
    it { is_expected.to validate_numericality_of(:service_fee_installments).only_integer.is_greater_than_or_equal_to(0).with_message("Must be an integer greater than or equal to zero") }
    it { is_expected.to validate_numericality_of(:service_fee_percentage).only_integer.is_greater_than_or_equal_to(0).with_message("Must be an integer greater than or equal to zero") }

    it { is_expected.to validate_numericality_of(:per_participant).is_greater_than(0).with_message("Must be greater than zero") }
    it { is_expected.to validate_numericality_of(:recruitment_target).only_integer.is_greater_than(0).with_message("Must be an integer greater than zero") }
  end
end
