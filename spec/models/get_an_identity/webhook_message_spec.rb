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

  describe "instance methods" do
    describe "#make_processed!" do
      it "sets status to processed and processed_at" do
        expect(subject).not_to be_processed_status
        expect(subject.processed_at).to be_nil

        subject.make_processed!

        expect(subject).to be_processed_status
        expect(subject.processed_at).to be_within(1.second).of(Time.zone.now)
      end
    end
  end
end
