require "rails_helper"

RSpec.describe Migration::ParityCheck::Client do
  let(:lead_provider) { create(:lead_provider) }
  let(:path) { "/api/path" }
  let(:method) { :get }
  let(:options) { {} }
  let(:instance) { described_class.new(lead_provider:, method:, path:, options:) }
  let(:ecf_url) { "http://ecf.example.com" }
  let(:npq_url) { "http://npq.example.com" }
  let(:keys) { { lead_provider.ecf_id => SecureRandom.uuid } }

  before do
    allow(Rails.application.config).to receive(:npq_separation) do
      {
        parity_check: {
          enabled: true,
          ecf_url:,
          npq_url:,
        },
      }
    end

    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("PARITY_CHECK_KEYS").and_return(keys.to_json)
  end

  describe "#initialize" do
    it { expect(instance.lead_provider).to eq(lead_provider) }
    it { expect(instance.path).to eq(path) }
    it { expect(instance.method).to eq(method) }
    it { expect(instance.options).to eq(options) }

    context "when options is nil" do
      let(:options) { nil }

      it { expect(instance.options).to eq({}) }
    end
  end

  describe "#make_requests" do
    let(:requests) { WebMock::RequestRegistry.instance.requested_signatures.hash.keys }
    let(:ecf_requests) { requests.select { |r| r.uri.host.include?("ecf") } }
    let(:npq_requests) { requests.select { |r| r.uri.host.include?("npq") } }

    context "when making a GET request" do
      let(:method) { :get }

      before do
        stub_request(:get, "#{ecf_url}#{path}").to_return(status: 200, body: "ecf_response_body")
        stub_request(:get, "#{npq_url}#{path}").to_return(status: 201, body: "npq_response_body")
      end

      it "makes a request to ECF/NPQ with correct path and headers" do
        instance.make_requests do
          requests.each do |request|
            expect(request.uri.path).to eq(path)
            expect(request.headers["Accept"]).to eq("application/json")
            expect(request.headers["Content-Type"]).to eq("application/json")
          end
        end
      end

      it "makes a request to ECF/NPQ with a valid authorization token for the lead provider" do
        instance.make_requests do
          ecf_token = ecf_requests.first.headers["Authorization"].partition("Bearer ").last
          expect(ecf_token).to eq(keys[lead_provider.ecf_id])

          npq_token = npq_requests.first.headers["Authorization"].partition("Bearer ").last
          expect(npq_token).to eq(keys[lead_provider.ecf_id])
        end
      end

      it "yeilds the result of each call to the block" do
        instance.make_requests do |ecf_result, npq_result, page|
          expect(ecf_result[:response].code).to eq(200)
          expect(ecf_result[:response].body).to eq("ecf_response_body")
          expect(ecf_result[:response_ms]).to be >= 0

          expect(npq_result[:response].code).to eq(201)
          expect(npq_result[:response].body).to eq("npq_response_body")
          expect(npq_result[:response_ms]).to be >= 0

          expect(page).to be_nil
        end
      end
    end
  end
end
