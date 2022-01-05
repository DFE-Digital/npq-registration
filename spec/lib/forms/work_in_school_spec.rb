require "rails_helper"

RSpec.describe Forms::WorkInSchool, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:works_in_school) }
    it { is_expected.to validate_inclusion_of(:works_in_school).in_array(described_class::VALID_WORK_IN_SCHOOL_OPTIONS) }
  end
end
