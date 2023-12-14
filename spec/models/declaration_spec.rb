require "rails_helper"

RSpec.describe Declaration, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:application_id) }
    it { is_expected.to validate_presence_of(:course_id) }
    it { is_expected.to validate_presence_of(:lead_provider_id) }
    it { is_expected.to validate_presence_of(:user_id) }
    it { is_expected.to validate_inclusion_of(:state).in_array(Declaration::STATES) }
  end
end
