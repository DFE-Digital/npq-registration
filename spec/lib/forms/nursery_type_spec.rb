require "rails_helper"

RSpec.describe Forms::NurseryType, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:nursery_type) }
    it { is_expected.to validate_inclusion_of(:nursery_type).in_array(described_class::ALL_OPTIONS) }
  end
end
