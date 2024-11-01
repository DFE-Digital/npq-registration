require "rails_helper"

RSpec.describe ParityCheckComparisonJob do
  let(:instance) { described_class.new }
  let(:lead_provider) { create(:lead_provider) }
  let(:request_method) { :get }
  let(:path) { "/path" }
  let(:options) { { paginate: true, exclude: %w[attribute] } }

  describe "#perform" do
    subject(:perform_comparison) { instance.perform(lead_provider:, method: request_method, path:, options:) }

    let(:client_double) { instance_double(Migration::ParityCheck::Client, make_requests: nil) }

    before do
      allow(Migration::ParityCheck::Client).to receive(:new).and_return(client_double)

      ecf_result_dpuble = { response: instance_double(HTTParty::Response, body: %({ "foo": "bar", "attribute": "excluded" }), code: 200), response_ms: 100 }
      npq_result_double = { response: instance_double(HTTParty::Response, body: "npq_response_body", code: 201), response_ms: 150 }

      allow(client_double).to receive(:make_requests).and_yield(ecf_result_dpuble, npq_result_double, "/formatted/path", 1)
    end

    it "calls the client and saves the resulting comparison" do
      expect(Migration::ParityCheck::ResponseComparison).to receive(:create!).with(
        lead_provider:,
        request_path: "/formatted/path",
        request_method:,
        ecf_response_status_code: 200,
        npq_response_status_code: 201,
        ecf_response_body: %({ "foo": "bar", "attribute": "excluded" }),
        npq_response_body: "npq_response_body",
        ecf_response_time_ms: 100,
        npq_response_time_ms: 150,
        exclude: %w[attribute],
        page: 1,
      ).and_call_original

      expect { perform_comparison }.to change(Migration::ParityCheck::ResponseComparison, :count).by(1)

      expect(client_double).to have_received(:make_requests).once
    end

    it "finalises the parity check" do
      expect(Migration::ParityCheck).to receive(:finalise!).once

      perform_comparison
    end
  end
end
