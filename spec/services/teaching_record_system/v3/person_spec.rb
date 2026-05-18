require "rails_helper"

RSpec.describe TeachingRecordSystem::V3::Person do
  let(:access_token) { "test-oauth-token" }
  let(:trn) { "1234567" }
  let(:base_url) { ENV["TRS_API_URL"] }

  let(:teaching_record_response) do
    {
      "trn" => trn,
      "firstName" => "Sarah",
      "middleName" => "Jane",
      "lastName" => "Smith",
      "previousNames" => [
        { "firstName" => "Sarah", "middleName" => "Jane", "lastName" => "Johnson" },
      ],
    }
  end

  let :stub_person_api do
    stub_request(:get, "#{base_url}/v3/person")
      .with(
        headers: {
          "Authorization" => "Bearer #{access_token}",
          "X-Api-Version" => "Next",
        },
        query: { "include" => "PreviousNames" },
      )
  end

  describe ".find_with_token" do
    subject(:call_api) { described_class.find_with_token(access_token:) }

    context "when successful" do
      before do
        stub_person_api
          .to_return(status: 200, body: teaching_record_response.to_json)
      end

      it "returns parsed teaching record" do
        record = described_class.find_with_token(access_token:)

        expect(record["trn"]).to eq(trn)
        expect(record["firstName"]).to eq("Sarah")
        expect(record["previousNames"]).to be_an(Array)
      end
    end

    context "when unauthorized (401)" do
      before { stub_person_api.to_return(status: 401) }

      it "raises ApiError with 401" do
        expect {
          call_api
        }.to raise_error(TeachingRecordSystem::ApiError, "API request failed (HTTP 401)")
      end
    end

    context "when timeout occurs" do
      before { stub_person_api.to_timeout }

      it "raises Timeout::Error" do
        expect {
          call_api
        }.to raise_error(TeachingRecordSystem::TimeoutError)
      end
    end

    context "when teaching record does not yet exist (403)" do
      before { stub_person_api.to_return(status: 403, body: "Forbidden") }

      it "raises a forbidden error" do
        expect {
          call_api
        }.to raise_error TeachingRecordSystem::ApiError, "API request failed (HTTP 403)"
      end
    end

    context "when server error (500)" do
      before { stub_person_api.to_return(status: 500, body: "Internal Server Error") }

      it "raises ApiError with 500" do
        expect {
          call_api
        }.to raise_error(TeachingRecordSystem::ApiError, "API request failed (HTTP 500)")
      end
    end
  end
end
