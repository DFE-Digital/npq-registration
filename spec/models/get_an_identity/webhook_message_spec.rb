require "rails_helper"

RSpec.describe GetAnIdentity::WebhookMessage, type: :model do
  describe "enums" do
    it {
      expect(subject).to define_enum_for(:status).with_values(
        pending: "pending",
        processing: "processing",
        processed: "processed",
        failed: "failed",
        unhandled_message_type: "unhandled_message_type",
      ).backed_by_column_of_type(:string).with_suffix
    }
  end
end
