require "rails_helper"
require "middleware/api_request_middleware"

RSpec.describe Middleware::ApiRequestMiddleware, type: :request do
  let(:status) { 200 }
  let(:request) { Rack::MockRequest.new(subject) }
  let(:headers) { { "HEADER" => "Yeah!" } }
  let(:mock_response) { ["Hellowwworlds!"] }

  let(:mock_app) do
    lambda do |env|
      @env = env
      [status, headers, mock_response]
    end
  end

  subject { described_class.new(mock_app) }

  before do
    allow(Rails).to receive(:env) { environment.inquiry }
    allow(StreamApiRequestsToBigQueryJob).to receive(:perform_later)
  end

  context "when running in other environments other than the allowed ones" do
    let(:environment) { "test" }

    it "does not fire StreamApiRequestsToBigQueryJob" do
      request.get "/"

      expect(StreamApiRequestsToBigQueryJob).not_to have_received(:perform_later)
    end
  end

  context "when running in allowed environments" do
    let(:environment) { "separation" }

    describe "#call on a non-API path" do
      it "does not fire StreamApiRequestsToBigQueryJob" do
        request.get "/"

        expect(StreamApiRequestsToBigQueryJob).not_to have_received(:perform_later)
      end
    end

    describe "#call on an API path" do
      it "fires an StreamApiRequestsToBigQueryJob" do
        request.get "/api/v1/participants/ecf", params: { foo: "bar" }

        expect(StreamApiRequestsToBigQueryJob).to have_received(:perform_later).with(
          hash_including("path" => "/api/v1/participants/ecf", "params" => { "foo" => "bar" }, "method" => "GET"), anything, 200, anything
        )
      end
    end

    describe "#call on a different version API path" do
      it "fires an StreamApiRequestsToBigQueryJob" do
        request.get "/api/v3/participants/ecf", params: { foo: "bar" }

        expect(StreamApiRequestsToBigQueryJob).to have_received(:perform_later).with(
          hash_including("path" => "/api/v3/participants/ecf", "params" => { "foo" => "bar" }, "method" => "GET"), anything, 200, anything
        )
      end
    end

    describe "#call on an API path with POST data" do
      it "fires an StreamApiRequestsToBigQueryJob including post data" do
        request.post "/api/v1/participant-declarations", as: :json, params: { foo: "bar" }.to_json

        expect(StreamApiRequestsToBigQueryJob).to have_received(:perform_later).with(
          hash_including("path" => "/api/v1/participant-declarations", "body" => '{"foo":"bar"}', "method" => "POST"), anything, 200, anything
        )
      end
    end

    describe "#call on an API path when an exception happens in the job" do
      it "logs the exception and returns" do
        allow(Rails.logger).to receive(:warn)
        allow(StreamApiRequestsToBigQueryJob).to receive(:perform_later).and_raise(StandardError)

        request.get "/api/v1/participants/ecf"

        expect(Rails.logger).to have_received(:warn)
      end
    end
  end
end
