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

    context "when the webhook message_type is UserUpdated" do
      let(:message_type) { "UserUpdated" }
      let(:message) { {} }

      it "sends webhook message to the UserUpdatedProcessor" do
        expect(GetAnIdentityService::Webhooks::UserUpdatedProcessor).to receive(:call).with(webhook_message:)
        described_class.perform_now(webhook_message:)
      end
    end
  end
end
