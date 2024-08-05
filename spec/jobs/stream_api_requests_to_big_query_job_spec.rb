# frozen_string_literal: true

require "rails_helper"

RSpec.describe StreamAPIRequestsToBigQueryJob, type: :job do
  subject(:job) { described_class.perform_now(request_data, response_data, status_code, created_at) }

  let(:bigquery) { instance_double("bigquery") }
  let(:dataset)  { instance_double("dataset") }
  let(:table)    { instance_double("table", insert: nil) }
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

  before do
    APIToken.create_with_known_token!("ambition-token", lead_provider:)

    allow(Google::Cloud::Bigquery).to receive(:new).and_return(bigquery)
    allow(bigquery).to receive(:dataset).and_return(dataset)
  end

  describe "#perform" do
    context "when the BigQuery table exists" do
      before do
        allow(dataset).to receive(:table).and_return(table)
      end

      it "enqueues a job" do
        expect {
          described_class.perform_later
        }.to have_enqueued_job
      end

      context "when API Request response is success" do
        it "sends correct data to BigQuery with no `response_body`" do
          job

          expect(table).to have_received(:insert).with([{
            request_path: request_data["path"],
            status_code:,
            request_headers: request_data["headers"].except("HTTP_AUTHORIZATION").to_json,
            request_method: request_data["method"],
            request_body: { "foo" => "bar" }.to_json,
            response_body: "{}",
            response_headers: response_data["headers"].to_json,
            lead_provider: lead_provider.name,
            created_at:,
          }.stringify_keys], ignore_unknown: true)
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

        it "sends correct data to BigQuery with `response_body`" do
          job

          expect(table).to have_received(:insert).with([{
            request_path: request_data["path"],
            status_code:,
            request_headers: request_data["headers"].except("HTTP_AUTHORIZATION").to_json,
            request_method: request_data["method"],
            request_body: { "foo" => "bar" }.to_json,
            response_body: {
              "errors" => [{
                "title" => "application",
                "detail" => "This NPQ application has already been accepted",
              }],
            }.to_json,
            response_headers: response_data["headers"].to_json,
            lead_provider: lead_provider.name,
            created_at:,
          }.stringify_keys], ignore_unknown: true)
        end
      end
    end

    context "when the BigQuery table does not exist" do
      before do
        allow(dataset).to receive(:table).and_return(nil)
      end

      it "doesn't attempt to stream" do
        job

        expect(table).not_to have_received(:insert)
      end
    end
  end
end
