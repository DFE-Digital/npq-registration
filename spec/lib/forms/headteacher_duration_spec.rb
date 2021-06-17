require "rails_helper"

RSpec.describe Forms::HeadteacherDuration, type: :model do
  describe "validations" do
    it { is_expected.to validate_inclusion_of(:headteacher_status).in_array(Forms::HeadteacherDuration::VALID_HEADTEACHER_STATUS_OPTIONS) }
  end
end
