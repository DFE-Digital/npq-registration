require "rails_helper"

RSpec.describe Forms::WorkInNursery, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:works_in_nursery) }
    it { is_expected.to validate_inclusion_of(:works_in_nursery).in_array(described_class::VALID_WORK_IN_NURSERY_OPTIONS) }
  end
end
