require "rails_helper"

RSpec.describe CourseGroup, type: :model do
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to have_many(:courses) }
  it { is_expected.to have_many(:schedules) }
end
