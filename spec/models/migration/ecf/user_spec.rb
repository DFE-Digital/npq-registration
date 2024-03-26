require "rails_helper"

RSpec.describe Migration::Ecf::User, type: :model do
  describe "associations" do
    it { is_expected.to have_many(:participant_identities) }
    it { is_expected.to have_one(:teacher_profile) }
    it { is_expected.to have_many(:npq_profiles).through(:teacher_profile) }
  end

  describe "instance methods" do
    subject(:instance) { create(:ecf_migration_user, :npq) }

    describe "#npq_applications" do
      let(:ecf_migration_user) { create(:ecf_migration_user, :npq) }

      it "returns the npq applications from user" do
        expect(instance.npq_applications.size).to eq(1)
      end
    end
  end
end
