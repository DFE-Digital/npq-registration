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

  context "when running in other environments other than the allowed ones" do
    before do
      allow(Rails.application.config.x)
        .to receive(:enable_api_request_middleware).and_return(false)
    end

    describe "#call on a non-API path" do
      it "does not fire StreamAPIRequestsToBigQueryJob" do
        request.get "/"

        expect(StreamAPIRequestsToBigQueryJob).not_to have_received(:perform_later)
      end
    end

    describe "#call on an API path" do
      it "does not fire StreamAPIRequestsToBigQueryJob" do
        request.get "/api/v3/participants/npq", params: { foo: "bar" }

        expect(StreamAPIRequestsToBigQueryJob).not_to have_received(:perform_later)
      end
    end
  end

  context "when running in allowed environments" do
    describe "#call on a non-API path" do
      it "does not fire StreamAPIRequestsToBigQueryJob" do
        request.get "/"

        expect(StreamAPIRequestsToBigQueryJob).not_to have_received(:perform_later)
      end
    end

    describe "#call on an API path" do
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
        request.post "/api/v3/participant-declarations", as: :json, params: { foo: "bar" }.to_json

        expect(StreamAPIRequestsToBigQueryJob).to have_received(:perform_later).with(
          hash_including("path" => "/api/v3/participant-declarations",
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

        request.get "/api/v3/participants/npq"

        expect(Rails.logger).to have_received(:warn)
      end
    end

    describe "#call on an API path when response code is not successful" do
      let(:status) { 404 }

      it "fires an StreamAPIRequestsToBigQueryJob with response body included" do
        request.get "/api/v3/participants/npq", params: { foo: "bar" }

        expect(StreamAPIRequestsToBigQueryJob).to have_received(:perform_later).with(
          hash_including("path" => "/api/v3/participants/npq",
                         "params" => { "foo" => "bar" },
                         "method" => "GET"),
          { "body" => "Hellowwworlds!", "headers" => { "HEADER" => "Yeah!" } },
          404,
          now,
        )
      end
    end

    describe "#call on non-tracked API paths" do
      it "does not fire StreamAPIRequestsToBigQueryJob for /api/guidance" do
        request.get "/api/guidance/some-page"

        expect(StreamAPIRequestsToBigQueryJob).not_to have_received(:perform_later)
      end

      it "does not fire StreamAPIRequestsToBigQueryJob for /api/docs" do
        request.get "/api/docs/v3"

        expect(StreamAPIRequestsToBigQueryJob).not_to have_received(:perform_later)
      end

      it "fires StreamAPIRequestsToBigQueryJob for other versioned API paths" do
        request.get "/api/v99/fake-endpoint"

        expect(StreamAPIRequestsToBigQueryJob).to have_received(:perform_later)
      end

      it "fires StreamAPIRequestsToBigQueryJob for /api/v1/get_an_identity" do
        request.post "/api/v1/get_an_identity/webhook_messages"

        expect(StreamAPIRequestsToBigQueryJob).to have_received(:perform_later)
      end
    end

    describe "#call with unprocessable content types" do
      it "does not fire StreamAPIRequestsToBigQueryJob for multipart/form-data" do
        request.post "/api/v3/participant-declarations",
                     "CONTENT_TYPE" => "multipart/form-data; boundary=----WebKitFormBoundary",
                     input: "some file data"

        expect(StreamAPIRequestsToBigQueryJob).not_to have_received(:perform_later)
      end

      it "does not fire StreamAPIRequestsToBigQueryJob for application/octet-stream" do
        request.post "/api/v3/participant-declarations",
                     "CONTENT_TYPE" => "application/octet-stream",
                     input: "\x00\x01\x02"

        expect(StreamAPIRequestsToBigQueryJob).not_to have_received(:perform_later)
      end

      it "fires StreamAPIRequestsToBigQueryJob for application/json with charset" do
        request.post "/api/v3/participant-declarations",
                     "CONTENT_TYPE" => "application/json; charset=utf-8",
                     input: '{"foo":"bar"}'

        expect(StreamAPIRequestsToBigQueryJob).to have_received(:perform_later)
      end
    end

    describe "#call with an oversized request body" do
      it "fires StreamAPIRequestsToBigQueryJob with truncation message instead of body" do
        large_body = "x" * (1_048_576 + 1)
        request.post "/api/v3/participant-declarations",
                     "CONTENT_TYPE" => "application/json",
                     input: large_body

        expect(StreamAPIRequestsToBigQueryJob).to have_received(:perform_later).with(
          hash_including("body" => "[truncated: body exceeded 1048576 bytes]"),
          anything,
          anything,
          anything,
        )
      end
    end
  end
end
