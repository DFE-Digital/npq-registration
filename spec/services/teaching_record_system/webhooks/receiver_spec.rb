require "rails_helper"

RSpec.describe TeachingRecordSystem::Webhooks::Receiver do
  describe ".call" do
    subject { described_class.call(webhook_params:) }

    let(:message_id) { SecureRandom.uuid }
    let(:user) { create(:user, :with_teacher_auth) }
    let(:sent_at_iso8601) { Time.zone.now.iso8601 }

    let(:webhook_params) do
      {
        message_id:,
        message_type: "trn_request.completed",
        sent_at: sent_at_iso8601,
        message:,
      }
    end

    let(:message) do
      {
        "trnRequest" => {
          "trn" => "1234567",
          "status" => "Completed",
          "potentialDuplicate" => true,
          "oneLoginUserSubject" => user.uid,
        },
      }
    end

    context "when the message has not been received before" do
      it "creates a GetAnIdentity::WebhookMessage" do
        expect { subject }.to change(GetAnIdentity::WebhookMessage, :count).by(1)
        expect(GetAnIdentity::WebhookMessage.last).to have_attributes(
          message_id:,
          message_type: "trn_request.completed",
          sent_at: Time.zone.parse(sent_at_iso8601),
          message:,
          status: "pending",
        )
      end

      it "enqueues a job to process the message" do
        expect { subject }.to have_enqueued_job(::GetAnIdentity::ProcessWebhookMessageJob)
      end

      it "returns true" do
        expect(subject).to be true
      end

      context "when the GetAnIdentity::WebhookMessage fails to save" do
        before do
          allow_any_instance_of(GetAnIdentity::WebhookMessage).to receive(:save).and_return(false)
        end

        it "returns false" do
          expect(subject).to be false
        end
      end
    end

    context "when the message has already been received" do
      before { create(:trs_trn_request_completed_webhook_message, message_id:, user_uid: user.uid, user_trn: user.trn) }

      it "does not create a new GetAnIdentity::WebhookMessage" do
        expect { subject }.not_to change(GetAnIdentity::WebhookMessage, :count)
      end

      it "does not enqueue a job to process the message" do
        expect { subject }.not_to have_enqueued_job(::GetAnIdentity::ProcessWebhookMessageJob)
      end

      it "returns true" do
        expect(subject).to be true
      end
    end
  end
end
