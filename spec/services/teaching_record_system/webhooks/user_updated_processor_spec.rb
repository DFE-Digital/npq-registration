require "rails_helper"

RSpec.describe TeachingRecordSystem::Webhooks::UserUpdatedProcessor do
  describe ".call" do
    subject { described_class.call(webhook_message:) }

    let(:user) { create(:user, :with_teacher_auth) }
    let(:new_trn) { "2345678" }
    let(:new_email) { "new@example.com" }

    let(:webhook_message) do
      create(
        :trs_user_updated_webhook_message,
        user_uid: user.uid,
        user_email: new_email,
        user_trn: new_trn,
      )
    end

    it "updates the user's email address" do
      subject
      expect(user.reload.email).to eq(new_email)
    end

    it "updates the user's TRN" do
      subject
      expect(user.reload).to have_attributes(
        trn: new_trn,
        trn_verified: true,
        trn_auto_verified: true,
      )
    end

    it "marks the webhook message as processed" do
      expect { subject }.to change(webhook_message, :status).from("pending").to("processed")
    end

    context "when the user has a refresh token" do
      let(:user) { create(:user, :with_teacher_auth, :with_refresh_token) }

      it "destroys the user's refresh token" do
        subject
        expect(user.refresh_token).to be_nil
      end
    end

    context "when there are other users with the same verified TRN" do
      let(:other_user) { create(:user, :with_get_an_identity_id, :with_verified_trn, trn: new_trn, created_at: 1.day.ago) }
      let(:more_recent_other_user) { create(:user, :with_teacher_auth, :with_verified_trn, trn: new_trn) }
      let(:application) { create(:application, :accepted, user: user) }
      let(:application_for_other_user) { create(:application, :accepted, user: other_user) }
      let(:application_for_more_recent_other_user) { create(:application, :accepted, user: more_recent_other_user) }

      before do
        application
        application_for_other_user
        application_for_more_recent_other_user
        create(:user, :archived, :with_get_an_identity_id, :with_verified_trn, trn: new_trn)
      end

      it "merges the other users into the most created user" do
        subject
        expect(user.reload).to be_archived
        expect(other_user.reload).to be_archived
        expect(application.reload.user).to eq more_recent_other_user
        expect(application_for_other_user.reload.user).to eq more_recent_other_user
        expect(more_recent_other_user.participant_id_changes.first).to have_attributes(from_participant_id: other_user.ecf_id, to_participant_id: more_recent_other_user.ecf_id)
        expect(more_recent_other_user.participant_id_changes.last).to have_attributes(from_participant_id: user.ecf_id, to_participant_id: more_recent_other_user.ecf_id)
      end
    end

    context "when there is no connected person" do
      let(:webhook_message) do
        create(
          :trs_user_updated_webhook_message,
          :no_connected_person,
          user_uid: user.uid,
          user_email: new_email,
        )
      end

      it "updates the user's email address" do
        subject
        expect(user.reload.email).to eq(new_email)
      end

      context "when the user has a refresh token" do
        let(:user) { create(:user, :with_teacher_auth, :with_refresh_token) }

        it "does not destroy the user's refresh token" do
          subject
          expect(user.refresh_token).not_to be_nil
        end
      end
    end

    context "when the message format is incorrect" do
      let(:webhook_message) { create(:trs_user_updated_webhook_message, user_uid: user.uid, user_trn: user.trn, message:) }

      let(:message) do
        {
          "wrongTopLevelElement" => {
            "subject" => user.uid,
            "emailAddress" => new_email,
          },
          "connectedPerson" => nil,
        }
      end

      it "marks the webhook message as failed" do
        subject
        expect(webhook_message.reload).to have_attributes(
          status: "failed",
          status_comment: "Invalid message format",
        )
      end
    end

    context "when the user cannot be found" do
      let(:webhook_message) { create(:trs_user_updated_webhook_message, user_uid: user_uid, user_trn: user.trn) }
      let(:user_uid) { "nonexistent-uid" }

      it "marks the webhook message as processed" do
        subject
        expect(webhook_message.reload).to have_attributes(
          status: "processed",
        )
      end
    end

    context "when the user UID is blank" do
      let(:webhook_message) { create(:trs_user_updated_webhook_message, user_uid: nil, user_trn: user.trn) }

      it "marks the webhook message as processed" do
        expect { subject }.to change(webhook_message, :status).from("pending").to("processed")
      end
    end
  end
end
