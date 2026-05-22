require "rails_helper"

RSpec.describe TeachingRecordSystem::Webhooks::TrnRequestCompletedProcessor do
  describe ".call" do
    subject { described_class.call(webhook_message:) }

    let(:webhook_message) { create(:trs_trn_request_completed_webhook_message, user_uid: user.uid, user_trn: new_trn) }
    let(:user) { create(:user, :with_teacher_auth) }
    let(:new_trn) { "2345678" }

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

      it "marks the webhook message as failed" do
        subject
        expect(webhook_message.reload).to have_attributes(
          status: "failed",
          status_comment: "No user found with uid: #{user_uid}",
        )
      end
    end
  end
end
