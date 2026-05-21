require "rails_helper"

RSpec.describe TeachingRecordSystem::Webhooks::Receiver do
  describe ".call" do
    context "when the message has not been received before" do
      it "creates a GetAnIdentity::WebhookMessage"

      it "enqueues a job to process the message"

      it "returns true"

      context "when the GetAnIdentity::WebhookMessage fails to save" do
        it "returns false"
      end
    end

    context "when the message has already been received" do
      it "does not create a new GetAnIdentity::WebhookMessage"

      it "does not enqueue a job to process the message"

      it "returns false"
    end
  end
end
