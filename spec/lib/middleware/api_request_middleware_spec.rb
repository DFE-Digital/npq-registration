require "rails_helper"
require "middleware/api_request_middleware"

RSpec.describe Middleware::ApiRequestMiddleware, type: :request do
  let(:status) { 200 }
  let(:request) { Rack::MockRequest.new(subject) }
  let(:headers) { { "HEADER" => "Yeah!" } }
  let(:mock_response) { ["Hellowwworlds!"] }
  let(:now) { Time.zone.now.to_s }

  let(:mock_app) do
    lambda do |env|
      @env = env
      [status, headers, mock_response]
    end
  end

  subject do
    freeze_time do
      described_class.new(mock_app)
    end
  end

  before do
    allow(Rails).to receive(:env) { environment.inquiry }
    allow(StreamAPIRequestsToBigQueryJob).to receive(:perform_later)
  end

  context "when running in other environments other than the allowed ones" do
    let(:environment) { "test" }

    describe "#call on a non-API path" do
      it "does not fire StreamAPIRequestsToBigQueryJob" do
        request.get "/"

        expect(StreamAPIRequestsToBigQueryJob).not_to have_received(:perform_later)
      end
    end

    describe "#call on an API path" do
      it "does not fire StreamAPIRequestsToBigQueryJob" do
        request.get "/api/v1/participants/npq", params: { foo: "bar" }

        expect(StreamAPIRequestsToBigQueryJob).not_to have_received(:perform_later)
      end
    end
  end

  context "when running in allowed environments" do
    let(:environment) { "production" }

    describe "#call on a non-API path" do
      it "does not fire StreamAPIRequestsToBigQueryJob" do
        request.get "/"

        expect(StreamAPIRequestsToBigQueryJob).not_to have_received(:perform_later)
      end
    end

    describe "#call on an API path" do
      it "fires a StreamAPIRequestsToBigQueryJob" do
        request.get "/api/v1/participants/npq", params: { foo: "bar" }

        expect(StreamAPIRequestsToBigQueryJob).to have_received(:perform_later).with(
          hash_including("path" => "/api/v1/participants/npq",
                         "params" => { "foo" => "bar" },
                         "method" => "GET"),
          { "body" => "", "headers" => { "HEADER" => "Yeah!" } },
          200,
          now,
        )
      end
    end

    describe "#call on a different version API path" do
      it "fires a StreamAPIRequestsToBigQueryJob" do
        request.get "/api/v3/participants/npq", params: { foo: "bar" }

        expect(StreamAPIRequestsToBigQueryJob).to have_received(:perform_later).with(
          hash_including("path" => "/api/v3/participants/npq",
                         "params" => { "foo" => "bar" },
                         "method" => "GET"),
          { "body" => "", "headers" => { "HEADER" => "Yeah!" } },
          200,
          now,
        )
      end
    end

    describe "#call on an API path with POST data" do
      it "fires a StreamAPIRequestsToBigQueryJob including post data" do
        request.post "/api/v1/participant-declarations", as: :json, params: { foo: "bar" }.to_json

        expect(StreamAPIRequestsToBigQueryJob).to have_received(:perform_later).with(
          hash_including("path" => "/api/v1/participant-declarations",
                         "body" => '{"foo":"bar"}',
                         "method" => "POST"),
          { "body" => "", "headers" => { "HEADER" => "Yeah!" } },
          200,
          now,
        )
      end
    end

    describe "#call on an API path when an exception happens in the job" do
      it "logs the exception and returns" do
        allow(Rails.logger).to receive(:warn)
        allow(StreamAPIRequestsToBigQueryJob).to receive(:perform_later).and_raise(StandardError)

        request.get "/api/v1/participants/npq"

        expect(Rails.logger).to have_received(:warn)
      end
    end

    describe "#call on an API path when response code is not successful" do
      let(:status) { 404 }

      it "fires an StreamAPIRequestsToBigQueryJob with response body included" do
        request.get "/api/v1/participants/npq", params: { foo: "bar" }

        expect(StreamAPIRequestsToBigQueryJob).to have_received(:perform_later).with(
          hash_including("path" => "/api/v1/participants/npq",
                         "params" => { "foo" => "bar" },
                         "method" => "GET"),
          { "body" => "Hellowwworlds!", "headers" => { "HEADER" => "Yeah!" } },
          404,
          now,
        )
      end
    end
  end
end
