require "rails_helper"

RSpec.describe Forms::HeadteacherDuration, type: :model do
  describe "validations" do
    it { is_expected.to validate_inclusion_of(:headerteacher_over_two_years).in_array(Forms::HeadteacherDuration::VALID_HEADERTEACHER_OVER_TWO_YEARS_OPTIONS) }
  end
end
