require "rails_helper"

RSpec.describe Contract, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:statement_id) }
    it { is_expected.to validate_presence_of(:course_id) }
    it { is_expected.to validate_presence_of(:cohort_id) }
    it { is_expected.to validate_presence_of(:lead_provider_id) }

    it { is_expected.to validate_numericality_of(:per_participant).is_greater_than(0) }
    it { is_expected.to validate_numericality_of(:recruitment_target).is_greater_than(0).only_integer }
    it { is_expected.to validate_numericality_of(:output_payment_percentage).is_greater_than(0).only_integer }
    it { is_expected.to validate_numericality_of(:number_of_payment_periods).is_greater_than(0).only_integer }
    it { is_expected.to validate_numericality_of(:service_fee_percentage).is_greater_than(0).only_integer }
    it { is_expected.to validate_numericality_of(:service_fee_installments).is_greater_than(0).only_integer }
  end
end
