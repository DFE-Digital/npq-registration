require "rails_helper"

RSpec.describe Forms::FindSchool, type: :model do
  describe "validations" do
    it { is_expected.to validate_length_of(:school_location).is_at_most(64) }
  end
end
