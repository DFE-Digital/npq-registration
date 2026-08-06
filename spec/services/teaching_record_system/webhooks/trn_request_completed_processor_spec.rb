require "rails_helper"

RSpec.describe TeachingRecordSystem::Webhooks::TrnRequestCompletedProcessor do
  describe ".call" do
    subject { described_class.call(webhook_message:) }

    let(:webhook_message) { create(:trs_trn_request_completed_webhook_message, user_uid: user.uid, user_trn: new_trn) }
    let(:user) { create(:user, :with_teacher_auth) }
    let(:new_trn) { "2345678" }

    context "when the user's TRN was initially set" do
      it "updates the user's TRN" do
        subject
        expect(user.reload).to have_attributes(
          trn: new_trn,
          trn_verified: true,
          trn_auto_verified: true,
        )
      end

      it "does not send a TRN allocated email" do
        expect(TrnAllocatedMailer).not_to send_mail(:trn_allocated_mail)
        subject
      end
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

    context "when the user's TRN was initially nil" do
      let(:user) { create(:user, :with_teacher_auth, trn: nil) }

      it "sends a TRN allocated email" do
        expect(TrnAllocatedMailer).to send_mail(:trn_allocated_mail)
          .with_params(to: user.email,
                       full_name: user.full_name,
                       trn: new_trn)
        subject
      end

      context "when the user's email is nil" do
        let(:user) { create(:user, :with_teacher_auth, :archived, trn: nil, email: nil) }

        it "does not send a TRN allocated email" do
          expect(TrnAllocatedMailer).not_to send_mail(:trn_allocated_mail)
          subject
        end
      end
    end

    context "when there are other users with the same verified TRN" do
      let(:other_user) { create(:user, :with_get_an_identity_id, :with_verified_trn, trn: new_trn) }
      let(:application) { create(:application, :accepted, user: other_user) }

      before do
        application
        create(:user, :archived, :with_get_an_identity_id, :with_verified_trn, trn: new_trn)
      end

      it "merges the other users into this user" do
        subject
        expect(other_user.reload).to be_archived
        expect(application.reload.user).to eq user
        expect(user.participant_id_changes.first).to have_attributes(from_participant_id: other_user.ecf_id, to_participant_id: user.ecf_id)
      end
    end

    context "when the message format is incorrect" do
      let(:webhook_message) { create(:trs_trn_request_completed_webhook_message, user_uid: user.uid, user_trn: new_trn, message:) }

      let(:message) do
        {
          "wrongTopLevelElement" => {
            "trn" => new_trn,
            "status" => "Completed",
            "potentialDuplicate" => true,
            "oneLoginUserSubject" => user.uid,
          },
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
      let(:webhook_message) { create(:trs_trn_request_completed_webhook_message, user_uid:, user_trn: new_trn) }
      let(:user_uid) { "nonexistent-uid" }

      it "marks the webhook message as processed" do
        expect { subject }.to change(webhook_message, :status).from("pending").to("processed")
      end
    end

    context "when the user UID is blank" do
      let(:webhook_message) { create(:trs_trn_request_completed_webhook_message, user_uid: nil, user_trn: new_trn) }

      it "marks the webhook message as processed" do
        expect { subject }.to change(webhook_message, :status).from("pending").to("processed")
      end
    end
  end
end
