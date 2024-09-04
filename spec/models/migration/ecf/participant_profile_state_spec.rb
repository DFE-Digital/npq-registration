require "rails_helper"

RSpec.describe Migration::Ecf::ParticipantProfileState, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:participant_profile) }
    it { is_expected.to belong_to(:cpd_lead_provider).optional }
  end
end
