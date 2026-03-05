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
        request["ce-time"] = Time.zone.now.iso8601
        request.content_type = "application/json"
        Linzer.sign!(request, key:, components:, label: "whsig")
      end
    end

    context "when a valid signed request is made" do
      let(:headers) do
        example_signed_request
          .to_hash
          .select { |key, _value| key.start_with?("signature") || components.include?(key) }
          .transform_values(&:first)
      end

      let(:trs_jwks) do
        jwk = JWT::JWK.import(public_key.material, alg: "ES384", kid: key_id, use: "sig")
        JWT::JWK::Set.new(jwk).export.to_json
      end

      before { stub_request(:get, "#{ENV.fetch('TRS_API_URL')}/webhook-jwks").to_return_json(body: trs_jwks) }

      it "creates a webhook message record" do
        expect { subject }.to change(TeachingRecordSystem::WebhookMessage, :count).by(1)
        webhook_message = TeachingRecordSystem::WebhookMessage.last
        expect(webhook_message.status_comment).to be_nil
        expect(webhook_message.status).to eq("pending")
        expect(webhook_message.raw).to eq(body)
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
        expect(TeachingRecordSystem::WebhookMessage.count).to eq 0
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
        expect(TeachingRecordSystem::WebhookMessage.count).to eq 0
      end
    end
  end
end
