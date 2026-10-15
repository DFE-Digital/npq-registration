require "rails_helper"

RSpec.describe GetAnIdentity::ProcessWebhookMessageJob do
  describe "#perform" do
    let(:webhook_message) do
      ::GetAnIdentity::WebhookMessage.create!(
        message:,
        message_id: SecureRandom.uuid,
        message_type:,
        raw: message.to_json,
        sent_at:,
      )
    end

    let(:sent_at) { Time.zone.now }

    context "when the message type is unknown" do
      let(:message_type) { "UserMerged" }
      let(:message) { {} }

      it "raises an exception so the job retries and we are notified" do
        expect {
          described_class.perform_now(webhook_message:)
        }.to raise_error(described_class::UnknownMessageTypeError, /No processor found for webhook message type: UserMerged/)
      end
    end

    context "when the message type is on the ignore list" do
      let(:message_type) { "UserMerged" }
      let(:message) { {} }

      before do
        stub_const("GetAnIdentity::WebhookMessage::IGNORED_MESSAGE_TYPES", %w[UserMerged])
      end

      it "silently ignores it by setting the status to unhandled_message_type" do
        expect {
          described_class.perform_now(webhook_message:)
        }.to change(webhook_message, :status).from("pending").to("unhandled_message_type")
      end
    end

    context "with a valid webhook message", :versioning do
      before do
        allow(TeachingRecordSystem::Webhooks::TrnRequestCompletedProcessor)
          .to receive(:call).and_call_original
      end

      let(:user) { create(:user, :with_teacher_auth, :without_trn) }
      let(:user_trn) { "2345678" }

      let :webhook_message do
        create(:trs_trn_request_completed_webhook_message, user_uid: user.uid, user_trn:)
      end

      let :expected_whodunnit do
        "Webhook: #{webhook_message.message_type}: #{webhook_message.id}"
      end

      it "processes the webhook" do
        expect { described_class.perform_now(webhook_message:) }
          .to change { user.reload.trn }.from(nil).to(user_trn)
              .and(change { user.versions.count }.by(1))
              .and(change { user.versions.last&.whodunnit }.from(nil).to(expected_whodunnit))

        expect(TeachingRecordSystem::Webhooks::TrnRequestCompletedProcessor)
          .to have_received(:call).with(webhook_message:)
      end
    end
  end
end
