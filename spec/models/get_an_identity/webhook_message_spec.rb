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

  describe "#make_processed!" do
    it "sets status to processed and processed_at" do
      expect(subject).not_to be_processed_status
      expect(subject.processed_at).to be_nil

      subject.make_processed!

      expect(subject).to be_processed_status
      expect(subject.processed_at).to be_within(1.second).of(Time.zone.now)
    end
  end

  describe "#processor_klass" do
    context "when message_type is alert.updated" do
      subject { build(:trs_user_updated_webhook_message) }

      it "returns a processor class" do
        expect(subject.processor_klass).to eq(TeachingRecordSystem::Webhooks::UserUpdatedProcessor)
      end
    end

    context "when message_type is trn_request.completed" do
      subject { build(:trs_trn_request_completed_webhook_message) }

      it "returns a processor class" do
        expect(subject.processor_klass).to eq(TeachingRecordSystem::Webhooks::TrnRequestCompletedProcessor)
      end
    end
  end
end
