require "rails_helper"

RSpec.describe Contract, type: :model do
  subject { build(:contract) }

  describe "relationships" do
    it { is_expected.to belong_to(:statement) }
    it { is_expected.to belong_to(:course) }
    it { is_expected.to belong_to(:contract_template) }
  end

  describe "validations" do
    it { is_expected.to validate_uniqueness_of(:course_id).scoped_to(:statement_id).with_message("Can only have one contract for statement and course") }
  end
end
