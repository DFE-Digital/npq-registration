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

  describe "#ignored_message_type?" do
    subject { build(:trs_user_updated_webhook_message, message_type:) }

    before do
      stub_const("GetAnIdentity::WebhookMessage::IGNORED_MESSAGE_TYPES", %w[ignore_me])
    end

    context "when the message_type is on the ignore list" do
      let(:message_type) { "ignore_me" }

      it { is_expected.to be_ignored_message_type }
    end

    context "when the message_type is not on the ignore list" do
      let(:message_type) { "one_login_user.updated" }

      it { is_expected.not_to be_ignored_message_type }
    end
  end

  describe "#processor_klass" do
    context "when message_type is one_login_user.updated" do
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
