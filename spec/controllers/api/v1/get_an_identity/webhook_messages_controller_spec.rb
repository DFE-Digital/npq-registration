require "rails_helper"

RSpec.describe Api::V1::GetAnIdentity::WebhookMessagesController do
  describe "POST create" do
    Dir.glob("spec/fixtures/requests/get_an_identity/webhooks/**/*.json").each do |file|
      context "for #{file}" do
        let(:raw_message) { File.read(file).strip }
        let(:message) { JSON.parse(raw_message) }

        let(:signature) do
          OpenSSL::HMAC.hexdigest("SHA256", signature_secret, raw_message)
        end

        let(:stubbed_secret) { SecureRandom.uuid }
        let(:signature_secret) { stubbed_secret }

        def send_request
          @request.headers["X-Hub-Signature-256"] = signature # rubocop:disable RSpec/InstanceVariable
          post(:create, params: message, as: :json)
        end

        before do
          allow(ENV).to receive(:[]).with("GET_AN_IDENTITY_WEBHOOK_SECRET").and_return(stubbed_secret)
        end

        it "responds with a success response code" do
          send_request
          expect(response).to be_successful
        end

        it "creates a ::GetAnIdentity::WebhookMessage record with thesend_request body parsed into the record" do
          expect {
            send_request
          }.to change(::GetAnIdentity::WebhookMessage, :count).by(1)

          webhook = ::GetAnIdentity::WebhookMessage.last
          expect(webhook.raw).to eq(message)
          expect(webhook.message).to eq(message["message"])
          expect(webhook.message_id).to eq(message["notificationId"])
          expect(webhook.message_type).to eq(message["messageType"])
          expect(webhook.sent_at).to eq(Time.zone.parse(message["timeUtc"]))
          expect(webhook.status).to eq "pending"
          expect(webhook.processed_at).to be_nil
          expect(webhook.status_comment).to be_nil
        end

        it "enqueues a job to process the webhook" do
          expect {
            send_request
          }.to have_enqueued_job(::GetAnIdentity::ProcessWebhookMessageJob)
        end

        context "when a message is received without the required fields" do
          let(:raw_message) { "{}" }

          it "returns a 200" do
            send_request
            expect(response).to have_http_status(:ok)
          end

          it "creates a ::GetAnIdentity::WebhookMessage record with thesend_request body parsed into the record" do
            expect {
              send_request
            }.to change(::GetAnIdentity::WebhookMessage, :count).by(1)

            webhook = ::GetAnIdentity::WebhookMessage.last
            expect(webhook.raw).to eq(message)
            expect(webhook.message).to be_nil
            expect(webhook.message_id).to be_nil
            expect(webhook.message_type).to be_nil
            expect(webhook.sent_at).to be_nil
            expect(webhook.status).to eq "pending"
            expect(webhook.processed_at).to be_nil
            expect(webhook.status_comment).to be_nil
          end

          it "enqueues a job to process the webhook" do
            expect {
              send_request
            }.to have_enqueued_job(::GetAnIdentity::ProcessWebhookMessageJob)
          end
        end

        context "when received message wasn't sent with the correct signature" do
          let(:signature_secret) { SecureRandom.uuid }

          it "returns a 401" do
            send_request
            expect(response).to have_http_status(:unauthorized)
          end

          it "does not persist a record" do
            expect {
              send_request
            }.not_to change(::GetAnIdentity::WebhookMessage, :count)
          end
        end

        context "when an already received message is repeated" do
          before do
            ::GetAnIdentity::WebhookMessage.create!(
              message: message["message"],
              message_id: message["notificationId"],
              message_type: message["messageType"],
              raw: message,
              sent_at: Time.zone.parse(message["timeUtc"]),
            )
          end

          it "does not create a new webhook record" do
            expect {
              send_request
            }.not_to change(::GetAnIdentity::WebhookMessage, :count)
          end

          it "does not enqueue a job to process the webhook" do
            expect {
              send_request
            }.not_to have_enqueued_job(::GetAnIdentity::ProcessWebhookMessageJob)
          end
        end

        context "when an already received message is repeated but the event type is different" do
          before do
            ::GetAnIdentity::WebhookMessage.create!(
              message_id: message["messageId"],
              message_type: "something else",
            )
          end

          it "creates a new webhook record" do
            expect {
              send_request
            }.to change(::GetAnIdentity::WebhookMessage, :count).by(1)
          end

          it "enqueues a job to process the webhook" do
            expect {
              send_request
            }.to have_enqueued_job(::GetAnIdentity::ProcessWebhookMessageJob)
          end
        end
      end
    end
  end
end
