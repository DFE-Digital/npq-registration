require "rails_helper"

RSpec.describe Migration::Ecf::NpqApplication, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:participant_identity) }
    it { is_expected.to belong_to(:npq_lead_provider) }
    it { is_expected.to belong_to(:npq_course) }
    it { is_expected.to belong_to(:cohort).optional }
    it { is_expected.to have_one(:profile).class_name("ParticipantProfile").with_foreign_key(:id) }
    it { is_expected.to have_one(:user).through(:participant_identity) }
    it { is_expected.to have_one(:school).class_name("School").with_foreign_key(:urn).with_primary_key(:school_urn) }
  end
end
