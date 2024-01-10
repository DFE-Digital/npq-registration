require "rails_helper"

RSpec.describe Schedule, type: :model do
  it { is_expected.to belong_to(:course_group) }
  it { is_expected.to belong_to(:cohort) }
  it { is_expected.to have_many(:applications) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:declaration_starts_on) }
    it { is_expected.to validate_presence_of(:schedule_applies_from) }
    it { is_expected.to validate_presence_of(:schedule_applies_to) }
    it { is_expected.to validate_presence_of(:declaration_types) }
  end
end
