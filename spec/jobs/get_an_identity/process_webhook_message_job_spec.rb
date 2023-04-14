require "rails_helper"

RSpec.describe GetAnIdentity::ProcessWebhookMessageJob do
  describe "#perform" do
    let(:webhook_message) {
      ::GetAnIdentity::WebhookMessage.create!(
        message: "{}",
        message_id: SecureRandom.uuid,
        message_type: "UserUpdated",
        raw: "{}",
        sent_at: Time.zone.now,
      )
    }

    context "when webhook message is unhandled" do
      it "updates the webhook message status to unhandled_message_type" do
        expect {
          described_class.perform_now(webhook_message: webhook_message)
        }.to change(webhook_message, :status).from("pending").to("unhandled_message_type")
      end
    end
  end
end
