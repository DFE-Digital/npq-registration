require "rails_helper"

RSpec.describe Users::ArchiveByEmail do
  describe ".call" do
    subject { described_class.new(user:).call }

    context "when there are matching users with the same email" do
      let!(:user) { create(:user, :with_get_an_identity_id, email: "user@example.com") }
      let(:matching_user) { create(:user, :with_get_an_identity_id, email: "match@example.com") }
      let!(:application_for_matching_user) { create(:application, :accepted, user: matching_user) }
      let!(:existing_participant_id_change) { create(:participant_id_change, user: matching_user) }

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

        it "moves existing participant id changes" do
          subject
          expect(existing_participant_id_change.reload.user).to eq user
        end

        context "when there is already a participant id change" do
          let!(:participant_id_change_on_user) { create(:participant_id_change, user:, from_participant_id: matching_user.ecf_id, to_participant_id: user.ecf_id) }

          it "does not create a duplicate participant id change" do
            subject
            expect(user.participant_id_changes).to contain_exactly(existing_participant_id_change, participant_id_change_on_user)
          end
        end
      end

      context "when the user passed has nil email" do
        before do
          user.email = nil
        end

        it "doesn't query the database (optimisation)" do
          expect(User).not_to receive(:where)
          subject
        end
      end
    end

    context "when the user passed is the only user that has that email" do
      let!(:user) { create(:user, :with_get_an_identity_id, email: "not_clashing@example.com") }

      it "does not archive the passed in user" do
        subject
        expect(user.reload).not_to be_archived
      end
    end
  end
end
