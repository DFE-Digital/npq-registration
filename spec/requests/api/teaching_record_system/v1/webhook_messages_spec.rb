require "rails_helper"

RSpec.describe "Teaching Record System webhooks", type: :request do
  describe "POST /api/v1/teaching_record_system/webhook_messages" do
    subject { post(path, headers:, params: body) }

    let(:path) { "/api/v1/teaching_record_system/webhook_messages" }
    let(:key_id) { "key1" }
    let(:key) { Linzer.generate_ecdsa_p384_sha384_key(key_id) }
    let(:public_key) { Linzer.new_ecdsa_p384_sha384_key(key.material.public_to_pem) }
    let(:content_digest) { "sha-256=:#{Base64.strict_encode64(Digest::SHA256.digest(body))}" }
    let(:components) { %w[@target-uri content-digest content-length ce-id ce-type ce-time] }
    let(:jwks_stub) { stub_request(:get, "#{ENV.fetch('TRS_API_URL')}/webhook-jwks").to_return_json(body: trs_jwks) }
    let(:memory_store) { ActiveSupport::Cache.lookup_store(:memory_store) }

    let(:body) do
      {
        "oneLoginUser": {
          "subject": "something",
          "emailAddress": "user@example.com",
        },
        "connectedPerson": {
          "trn": "0000000",
        },
      }.to_json
    end

    let(:example_signed_request) do
      Net::HTTP::Post.new(URI("http://www.example.com#{path}")).tap do |request|
        request.body = body
        request["content-digest"] = content_digest
        request["content-length"] = request.body.length.to_s
        request["ce-id"] = SecureRandom.uuid
        request["ce-type"] = "one_login_user.updated"
        request["ce-source"] = "https://preprod.teacher-qualifications-api.education.gov.uk"
        request["ce-time"] = Time.zone.now.iso8601
        request.content_type = "application/json"
        Linzer.sign!(request, key:, components:, label: "whsig")
      end
    end

    context "when a valid signed request is made" do
      let(:headers_to_include) do
        %w[
          ce-id
          ce-source
          ce-time
          ce-type
          content-digest
          content-length
          signature
          signature-input
        ]
      end

      let(:headers) do
        example_signed_request
          .to_hash
          .select { |key, _value| headers_to_include.include?(key) }
          .transform_values(&:first)
      end

      let(:trs_jwks) do
        jwk = JWT::JWK.import(public_key.material, alg: "ES384", kid: key_id, use: "sig")
        JWT::JWK::Set.new(jwk).export.to_json
      end

      before do
        jwks_stub
        allow(Rails).to receive(:cache).and_return(memory_store)
      end

      it "creates a webhook message record" do
        expect { subject }.to change(CloudEvent::WebhookMessage, :count).by(1)
        webhook_message = CloudEvent::WebhookMessage.last
        expect(webhook_message).to have_attributes(
          cloud_event_id: example_signed_request["ce-id"],
          cloud_event_type: example_signed_request["ce-type"],
          cloud_event_source: example_signed_request["ce-source"],
          status_comment: nil,
          status: "pending",
          raw: body,
        )

        expect(webhook_message.status_comment).to be_nil
        expect(webhook_message.status).to eq("pending")
        expect(webhook_message.raw).to eq(body)
      end

      it "caches the JWKS response for a day" do
        post(path, headers:, params: body)
        post(path, headers:, params: body)
        expect(jwks_stub).to have_been_requested.once
        travel 25.hours
        post(path, headers:, params: body)
        expect(jwks_stub).to have_been_requested.twice
      end

      context "when the JWKS endpoint is not working" do
        let(:jwks_stub) { stub_request(:get, "#{ENV.fetch('TRS_API_URL')}/webhook-jwks").to_return(status: 500) }

        it "does something"
      end

      context "when the JWKS response does not contain the expected key" do
        let(:trs_jwks) do
          jwk = JWT::JWK.import(public_key.material, alg: "ES384", kid: "key2", use: "sig")
          JWT::JWK::Set.new(jwk).export.to_json
        end

        it "returns a 401 response" do
          subject
          expect(response.status).to eq 401
        end
      end
    end

    context "when a invalid signed request is made" do
      let(:headers) do
        example_signed_request
          .to_hash
          .select { |key, _value| key == "signature-input" || components.include?(key) }
          .transform_values(&:first).merge({ "signature" => "invalidsignature" })
      end

      it "returns a 401 response" do
        subject
        expect(response.status).to eq 401
      end

      it "does not create a webhook message record" do
        subject
        expect(CloudEvent::WebhookMessage.count).to eq 0
      end
    end

    context "when an unsigned request is made" do
      let(:headers) do
        example_signed_request
          .to_hash
          .select { |key, _value| components.include?(key) }
          .transform_values(&:first)
      end

      it "returns a 401 response" do
        subject
        expect(response.status).to eq 401
      end

      it "does not create a webhook message record" do
        subject
        expect(CloudEvent::WebhookMessage.count).to eq 0
      end
    end
  end
end
