require "rails_helper"

RSpec.describe Migration::Ecf::NpqCourse, type: :model do
  describe "associations" do
    it { is_expected.to have_many(:npq_applications) }
  end
end
