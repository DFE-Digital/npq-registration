require "rails_helper"

RSpec.describe Migration::Ecf::ParticipantIdentity, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:participant_profiles) }
    it { is_expected.to have_many(:npq_applications) }
  end
end
