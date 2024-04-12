require "rails_helper"

RSpec.describe Migration::Ecf::ParticipantProfile, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:teacher_profile) }
    it { is_expected.to belong_to(:schedule).class_name("Finance::Schedule") }
    it { is_expected.to have_one(:user).through(:teacher_profile) }
    it { is_expected.to have_one(:npq_application).with_foreign_key(:id) }
  end

  describe "scopes" do
    describe "default_scope" do
      let!(:ecf_migration_user) { create(:ecf_migration_user, :npq) }

      it "returns NPQ profiles only" do
        expect(described_class.all).to eq([ecf_migration_user.npq_profiles.first])
      end
    end
  end
end
