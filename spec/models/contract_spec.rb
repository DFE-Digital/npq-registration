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
    it { is_expected.to validate_uniqueness_of(:course_id).scoped_to(:statement_id).with_message("can only have one contract for statement and course") }
  end
end
