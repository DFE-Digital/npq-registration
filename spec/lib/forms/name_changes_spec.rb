require "rails_helper"

RSpec.describe Forms::NameChanges, type: :model do
  describe "validations" do
    it { is_expected.to validate_inclusion_of(:changed_name).in_array(Forms::NameChanges::VALID_CHANGED_NAME_OPTIONS) }
  end
end
