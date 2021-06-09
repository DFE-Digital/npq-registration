require "rails_helper"

RSpec.describe Forms::NotUpdatedName, type: :model do
  describe "validations" do
    it { is_expected.to validate_inclusion_of(:name_not_updated_action).in_array(Forms::NotUpdatedName::VALID_NAME_NOT_UPDATED_ACTION_OPTIONS) }
  end
end
