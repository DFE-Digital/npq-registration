require "rails_helper"

RSpec.describe Questionnaires::FindSchool, type: :model do
  describe "validations" do
    it { is_expected.to validate_length_of(:institution_location).is_at_most(64) }
  end
end
