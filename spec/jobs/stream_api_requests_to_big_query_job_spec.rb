# frozen_string_literal: true

require "rails_helper"

RSpec.describe StreamAPIRequestsToBigQueryJob, type: :job do
  subject(:job) { described_class.perform_now(request_data, response_data, status_code, created_at) }

  let(:status_code) { 200 }
  let(:created_at) { Time.zone.now.to_s }
  let(:lead_provider) { LeadProvider.find_by(name: "Ambition Institute") }

  let(:request_data) do
    {
      "path" => "/api/v3/participants/npq",
      "params" => {},
      "body" => { "foo" => "bar" }.to_json,
      "headers" => {
        "HTTP_VERSION" => "HTTP/1.1",
        "HTTP_HOST" => "localhost:3000",
        "HTTP_USER_AGENT" => "PostmanRuntime/7.39.0",
        "HTTP_ACCEPT" => "*/*",
        "HTTP_ACCEPT_ENCODING" => "gzip, deflate, br",
        "HTTP_AUTHORIZATION" => "Bearer ambition-token",
        "HTTP_CONNECTION" => "keep-alive",
        "QUERY_STRING" => "",
      },
      "method" => "GET",
    }
  end
  let(:response_data) do
    {
      "headers" => { "Content-Type" => "application/json" },
      "body" => {
        "data" => [{
          "id" => "123456",
          "type" => "npq-participant",
          "attributes" => {
            "full_name": "Test Example",
            "teacher_reference_number": "123",
          },
        }],
      }.to_json,
    }
  end

  let(:analytics_event) { instance_double(DfE::Analytics::Event) }

  before do
    APIToken.create_with_known_token!("ambition-token", lead_provider:)

    allow(DfE::Analytics::Event).to receive(:new) { analytics_event }
    allow(analytics_event).to receive(:with_type).with(:persist_api_request) { analytics_event }
    allow(analytics_event).to receive(:with_namespace).with("npq") { analytics_event }
    allow(analytics_event).to receive(:with_user).with(lead_provider) { analytics_event }
  end

  describe "#perform" do
    before do
      allow(described_class).to receive(:perform_later).and_call_original
    end

    it "enqueues a job with the correct arguments" do
      expect {
        described_class.perform_later(request_data, response_data, status_code, created_at)
      }.to have_enqueued_job.with(request_data, response_data, status_code, created_at)
    end

    context "when logging" do
      let(:io)  { StringIO.new }
      let(:log) { io.tap(&:rewind).read }
      let(:log_line) { log.lines.find { |line| line.include? described_class.to_s } }
      let(:pii) { /teacher_reference_number.*123/ }

      before do
        SemanticLogger.add_appender(io:, level: :info)
        SemanticLogger.sync!
        allow(analytics_event).to receive(:with_data) { analytics_event }
        job
      end

      it "does not log the parameters used in the request" do
        expect(log_line).to be_present
        expect(log_line).not_to include(pii)
      end
    end

    context "when API Request response is success" do
      it "sends a DfE::Analytics custom event" do
        expect(analytics_event).to receive(:with_data).with(
          data: {
            request_path: request_data["path"],
            status_code:,
            request_headers: request_data["headers"].except("HTTP_AUTHORIZATION"),
            request_method: request_data["method"],
            request_body: { "foo" => "bar" },
            response_body: {},
            response_headers: response_data["headers"],
            lead_provider: lead_provider.name,
            created_at:,
          },
        )

        job
      end

      context "when there is no `response_body`" do
        let(:response_data) do
          {
            "headers" => { "Content-Type" => "application/json" },
            "body" => nil,
          }
        end

        it "sends a DfE::Analytics custom event" do
          expect(analytics_event).to receive(:with_data).with(
            data: {
              request_path: request_data["path"],
              status_code:,
              request_headers: request_data["headers"].except("HTTP_AUTHORIZATION"),
              request_method: request_data["method"],
              request_body: { "foo" => "bar" },
              response_body: {},
              response_headers: response_data["headers"],
              lead_provider: lead_provider.name,
              created_at:,
            },
          )

          job
        end
      end
    end

    context "when API Request response is not success" do
      let(:status_code) { 422 }
      let(:response_data) do
        {
          "headers" => { "Content-Type" => "application/json" },
          "body" => {
            "errors" => [{
              "title" => "application",
              "detail" => "This NPQ application has already been accepted",
            }],
          }.to_json,
        }
      end

      it "sends a DfE::Analytics custom event" do
        expect(analytics_event).to receive(:with_data).with(
          data: {
            request_path: request_data["path"],
            status_code:,
            request_headers: request_data["headers"].except("HTTP_AUTHORIZATION"),
            request_method: request_data["method"],
            request_body: { "foo" => "bar" },
            response_body: {
              "errors" => [{
                "title" => "application",
                "detail" => "This NPQ application has already been accepted",
              }],
            },
            response_headers: response_data["headers"],
            lead_provider: lead_provider.name,
            created_at:,
          },
        )

        job
      end
    end

    context "when no `auth_token`` has been used in the request" do
      let(:request_data) do
        {
          "path" => "/api/v3/participants/npq",
          "params" => {},
          "body" => { "foo" => "bar" }.to_json,
          "headers" => {
            "HTTP_VERSION" => "HTTP/1.1",
            "HTTP_HOST" => "localhost:3000",
            "HTTP_USER_AGENT" => "PostmanRuntime/7.39.0",
            "HTTP_ACCEPT" => "*/*",
            "HTTP_ACCEPT_ENCODING" => "gzip, deflate, br",
            "HTTP_CONNECTION" => "keep-alive",
            "QUERY_STRING" => "",
          },
          "method" => "GET",
        }
      end

      it "does not send a DfE::Analytics custom event" do
        expect(analytics_event).not_to receive(:with_data).with(
          data: {
            request_path: request_data["path"],
            status_code:,
            request_headers: request_data["headers"],
            request_method: request_data["method"],
            request_body: { "foo" => "bar" },
            response_body: {},
            response_headers: response_data["headers"],
            lead_provider: nil,
            created_at:,
          },
        )

        job
      end
    end

    context "when there is no `request_body`" do
      let(:request_data) do
        {
          "path" => "/api/v3/participants/npq",
          "params" => { "data" => { "attributes" => { "course_identifier" => "test-course" } } },
          "body" => nil,
          "headers" => {
            "HTTP_VERSION" => "HTTP/1.1",
            "HTTP_HOST" => "localhost:3000",
            "HTTP_USER_AGENT" => "PostmanRuntime/7.39.0",
            "HTTP_ACCEPT" => "*/*",
            "HTTP_ACCEPT_ENCODING" => "gzip, deflate, br",
            "HTTP_AUTHORIZATION" => "Bearer ambition-token",
            "HTTP_CONNECTION" => "keep-alive",
            "QUERY_STRING" => "",
          },
          "method" => "GET",
        }
      end

      it "sends a DfE::Analytics custom event" do
        expect(analytics_event).to receive(:with_data).with(
          data: {
            request_path: request_data["path"],
            status_code:,
            request_headers: request_data["headers"].except("HTTP_AUTHORIZATION"),
            request_method: request_data["method"],
            request_body: { "data" => { "attributes" => { "course_identifier" => "test-course" } } },
            response_body: {},
            response_headers: response_data["headers"],
            lead_provider: lead_provider.name,
            created_at:,
          },
        )
        job
      end
    end

    context "when `request_body` is invalid" do
      let(:request_data) do
        {
          "path" => "/api/v3/participants/npq",
          "params" => {},
          "body" => "invalid-body",
          "headers" => {
            "HTTP_VERSION" => "HTTP/1.1",
            "HTTP_HOST" => "localhost:3000",
            "HTTP_USER_AGENT" => "PostmanRuntime/7.39.0",
            "HTTP_ACCEPT" => "*/*",
            "HTTP_ACCEPT_ENCODING" => "gzip, deflate, br",
            "HTTP_AUTHORIZATION" => "Bearer ambition-token",
            "HTTP_CONNECTION" => "keep-alive",
            "QUERY_STRING" => "",
          },
          "method" => "GET",
        }
      end

      it "sends a DfE::Analytics custom event with an error message in the `request_body`" do
        expect(analytics_event).to receive(:with_data).with(
          data: {
            request_path: request_data["path"],
            status_code:,
            request_headers: request_data["headers"].except("HTTP_AUTHORIZATION"),
            request_method: request_data["method"],
            request_body: { error: "request data did not contain valid JSON" },
            response_body: {},
            response_headers: response_data["headers"],
            lead_provider: lead_provider.name,
            created_at:,
          },
        )
        job
      end
    end
  end
end
