require "rails_helper"

RSpec.describe CourseGroup, type: :model do
  subject { build(:course_group) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:name).with_message("Enter a unique course group name") }
    it { is_expected.to validate_uniqueness_of(:name).with_message("Course name already exist, enter a unique name") }
  end

  describe "associations" do
    it { is_expected.to have_many(:courses) }
  end
end
