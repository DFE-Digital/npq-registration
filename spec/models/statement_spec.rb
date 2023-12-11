require "rails_helper"

RSpec.describe Statement, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:cohort_id) }
    it { is_expected.to validate_presence_of(:lead_provider_id) }
    it { is_expected.to validate_numericality_of(:month).is_in(1..12).only_integer }
    it { is_expected.to validate_numericality_of(:year).is_in(2020..2030).only_integer }
  end
end
