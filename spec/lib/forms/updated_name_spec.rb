require "rails_helper"

RSpec.describe Forms::UpdatedName, type: :model do
  describe "validations" do
    it { is_expected.to validate_inclusion_of(:updated_name).in_array(Forms::UpdatedName::VALID_UPDATED_NAME_OPTIONS) }
  end
end
