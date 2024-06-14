require "rails_helper"

RSpec.describe Declaration, type: :model do
  subject { build(:declaration) }

  describe "associations" do
    it { is_expected.to belong_to(:application) }
    it { is_expected.to belong_to(:cohort) }
    it { is_expected.to belong_to(:lead_provider) }
    it { is_expected.to belong_to(:superseded_by).optional }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:declaration_type) }
    it { is_expected.to validate_presence_of(:declaration_date) }
  end
end
