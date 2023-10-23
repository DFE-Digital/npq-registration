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

    context "when webhook message is unhandled" do
      let(:message_type) { "UserMerged" }
      let(:message) { {} }

      it "updates the webhook message status to unhandled_message_type" do
        expect {
          described_class.perform_now(webhook_message:)
        }.to change(webhook_message, :status).from("pending").to("unhandled_message_type")
      end
    end

    context "when the webhook message_type is UserUpdated" do
      let(:message_type) { "UserUpdated" }
      let(:message) { {} }

      it "sends webhook message to the UserUpdatedProcessor" do
        expect(GetAnIdentity::Webhooks::UserUpdatedProcessor).to receive(:call).with(webhook_message:)
        described_class.perform_now(webhook_message:)
      end
    end
  end
end
