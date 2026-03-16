require "rails_helper"

RSpec.describe GetAnIdentityService::Webhooks::JwksFetcher do
  subject(:jwks_fetch) { described_class.new.call(request_key_id) }

  let(:key_id) { "key1" }
  let(:request_key_id) { key_id }
  let(:key) { Linzer.generate_ecdsa_p384_sha384_key(key_id) }
  let(:jwks_stub) { stub_request(:get, "#{ENV.fetch('TRS_API_URL')}/webhook-jwks").to_return_json(body: trs_jwks) }
  let(:public_key) { Linzer.new_ecdsa_p384_sha384_key(key.material.public_to_pem) }
  let(:memory_store) { ActiveSupport::Cache.lookup_store(:memory_store) }

  let(:trs_jwks) do
    jwk = JWT::JWK.import(public_key.material, alg: "ES384", kid: key_id, use: "sig")
    JWT::JWK::Set.new(jwk).export.to_json
  end

  before do
    jwks_stub
    allow(Rails).to receive(:cache).and_return(memory_store)
  end

  it "fetches the JWKS key" do
    expect(subject.material.to_pem).to eq public_key.material.to_pem
  end

  it "caches the JWKS key for a day" do
    described_class.new.call(key_id)
    described_class.new.call(key_id)
    expect(jwks_stub).to have_been_requested.once
    travel 25.hours
    described_class.new.call(key_id)
    expect(jwks_stub).to have_been_requested.twice
  end

  context "when the required key_id is not available" do
    let(:request_key_id) { "key2" }

    it "returns nil" do
      expect(subject).to be_nil
    end
  end

  context "when the JWKS endpoint is unavailable" do
    let(:jwks_stub) do
      stub_request(:get, "#{ENV.fetch('TRS_API_URL')}/webhook-jwks")
        .to_return(status: [500, "Internal Server Error"]).then
        .to_return_json(body: trs_jwks)
    end

    it "retries once" do
      expect(subject.material.to_pem).to eq public_key.material.to_pem
    end
  end
end
