require "rails_helper"

RSpec.describe CourseGroup, type: :model do
  it { should validate_presence_of(:name) }
  it { should have_many(:courses) }
end
