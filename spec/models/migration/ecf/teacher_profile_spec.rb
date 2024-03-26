require "rails_helper"

RSpec.describe Migration::Ecf::TeacherProfile, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:npq_profiles).class_name("ParticipantProfile") }
    it { is_expected.to have_many(:participant_profiles) }
  end
end
