require "rails_helper"

RSpec.describe Migration::Ecf::User, type: :model do
  describe "migration convenience methods" do
    let(:user) { create(:ecf_user, :teacher) }

    it { expect(user.ecf_id).to eq(user.id) }
    it { expect(user.trn).to eq(user.teacher_profile.trn) }

    describe "#applications" do
      let(:participant_identity) { create(:ecf_participant_identity, user:) }
      let!(:applications) { 3.times.collect { create(:ecf_npq_application, participant_identity:) } }

      it { expect(user.applications).to match_array(applications) }
      it { expect(user.applications).to match_array(user.migration_npq_applications) }
    end
  end
end
