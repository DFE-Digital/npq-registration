require "rails_helper"

RSpec.describe Migration::Ecf::ParticipantIdChange, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:from_participant) }
    it { is_expected.to belong_to(:to_participant) }
  end
end
