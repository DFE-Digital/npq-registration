require "rails_helper"

RSpec.describe Users::ArchiveByEmail do
  let!(:user) { create(:user, :with_get_an_identity_id, email: "user@example.com") }
  let(:matching_user) { create(:user, :with_get_an_identity_id, email: "match@example.com") }
  let!(:application_for_matching_user) { create(:application, :accepted, user: matching_user) }

  describe ".call" do
    subject { described_class.new(user:).call }

    before do
      user.email = "match@example.com"
    end

    it "moves applications from the matching users" do
      subject
      expect(application_for_matching_user.reload.user).to eq user
    end

    it "archives users matching the email" do
      subject
      expect(matching_user.reload).to be_archived
    end

    context "when feature flag ecf_api_disabled? is enabled" do
      before do
        Flipper.enable(Feature::ECF_API_DISABLED)
      end

      it "creates a participant id change" do
        subject
        expect(user.participant_id_changes.first).to have_attributes(from_participant_id: matching_user.ecf_id, to_participant_id: user.ecf_id)
      end
    end
  end
end
