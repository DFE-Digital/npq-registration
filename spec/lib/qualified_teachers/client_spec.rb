# frozen_string_literal: true

require "rails_helper"
require "qualified_teachers"

RSpec.describe QualifiedTeachers::Client do
  let(:user) { create(:user, trn: "1234567") }
  let(:stub_api_request) do
    stub_request(:put, "https://qualified-teachers-api.example.com/v2/npq-qualifications?trn=1234567")
      .with(
        body: "{\"completionDate\":\"2023-02-20\",\"qualificationType\":\"NPQSL\"}",
        headers: {
          "Accept" => "*/*",
          "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
          "Authorization" => "Bearer some-apikey-guid",
          "Content-Type" => "application/json",
          "Host" => "qualified-teachers-api.example.com",
          "User-Agent" => "Ruby",
        },
      )
      .to_return(status: 204, body: "", headers: {})
  end
  let(:stub_api_404_request) do
    stub_request(:put, "https://qualified-teachers-api.example.com/v2/npq-qualifications?trn=#{incorrect_trn}")
      .with(
        body: "{\"completionDate\":\"2023-02-20\",\"qualificationType\":\"NPQSL\"}",
        headers: {
          "Accept" => "*/*",
          "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
          "Authorization" => "Bearer some-apikey-guid",
          "Content-Type" => "application/json",
          "Host" => "qualified-teachers-api.example.com",
          "User-Agent" => "Ruby",
        },
      )
      .to_return(status: 404, body: { "title": "Teacher with specified TRN not found", "status": 404, "errorCode": 10_001 }.to_json, headers: {})
  end
  let(:stub_api_too_many_requests) do
    stub_request(:put, "https://qualified-teachers-api.example.com/v2/npq-qualifications?trn=1234567")
      .with(
        body: "{\"completionDate\":\"2023-02-20\",\"qualificationType\":\"NPQSL\"}",
        headers: {
          "Accept" => "*/*",
          "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
          "Authorization" => "Bearer some-apikey-guid",
          "Content-Type" => "application/json",
          "Host" => "qualified-teachers-api.example.com",
          "User-Agent" => "Ruby",
        },
      )
      .to_return(status: 429, body: "", headers: {})
  end
  let(:stub_api_different_record_request) do
    stub_request(:put, "https://qualified-teachers-api.example.com/v2/npq-qualifications?trn=1234567")
      .with(
        body: "{\"completionDate\":\"2023-02-20\",\"qualificationType\":\"NPQSL\"}",
        headers: {
          "Accept" => "*/*",
          "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
          "Authorization" => "Bearer some-apikey-guid",
          "Content-Type" => "application/json",
          "Host" => "qualified-teachers-api.example.com",
          "User-Agent" => "Ruby",
        },
      )
      .to_return(status: 400, body: "", headers: {})
  end
  let(:course) { create(:course, :senior_leadership) }
  let(:declaration) { create_declaration(:completed, user:, course:) }
  let!(:participant_outcome) { create(:participant_outcome, declaration:, completion_date: Time.zone.local(2023, 2, 20, 17, 30, 0).rfc3339) }
  let(:trn) { participant_outcome.declaration.user.trn }
  let(:incorrect_trn) { "1001009" }
  let(:request_body) do
    {
      completionDate: "2023-02-20",
      qualificationType: "NPQSL",
    }
  end
  let(:params) do
    {
      trn:,
      request_body:,
    }
  end

  subject { described_class.new }

  describe "#send_record" do
    describe "valid request" do
      it "returns success" do
        stub_api_request

        record = subject.send_record(trn:, request_body:)

        expect(record.response.code).to eq("204")
      end
    end

    describe "invalid request" do
      context "when record with given trn does not exist" do
        it "returns error code" do
          stub_api_404_request

          record = subject.send_record(trn: incorrect_trn, request_body:)

          expect(record.response.code).to eq("404")
        end
      end

      context "when api had too many requests" do
        it "raises an exception" do
          stub_api_too_many_requests

          expect { subject.send_record(trn:, request_body:) }.to raise_error(TooManyRequests)
        end
      end

      context "when api had a different error code" do
        it "returns error code" do
          stub_api_different_record_request

          record = subject.send_record(trn:, request_body:)

          expect(record.response.code).to eq("400")
        end
      end
    end

    context "when API key is not present" do
      before do
        allow(ENV).to receive(:[]).with("QUALIFIED_TEACHERS_API_KEY").and_return(nil)
      end

      it "raises an exception" do
        expect { subject.send_record(trn:, request_body:) }.to raise_error(RuntimeError, "Qualified Teachers API Key is not present")
      end
    end
  end
end
