require "rails_helper"

RSpec.describe Schedule, type: :model do
  it { is_expected.to belong_to(:course_group) }
  it { is_expected.to belong_to(:cohort) }
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:declaration_start_date) }
  it { is_expected.to validate_presence_of(:starts_on) }
  it { is_expected.to validate_presence_of(:ends_on) }
end
