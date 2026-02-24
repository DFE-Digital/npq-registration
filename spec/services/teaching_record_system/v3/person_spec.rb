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

  describe ".find_with_token" do
    context "when successful" do
      before do
        stub_request(:get, "#{base_url}/v3/person")
          .with(
            headers: {
              "Authorization" => "Bearer #{access_token}",
              "X-Api-Version" => "Next",
            },
            query: { "include" => "PreviousNames" },
          )
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
      before do
        stub_request(:get, "#{base_url}/v3/person")
          .with(
            headers: {
              "Authorization" => "Bearer #{access_token}",
              "X-Api-Version" => "Next",
            },
            query: { "include" => "PreviousNames" },
          )
          .to_return(status: 401)
      end

      it "raises ApiError with 401" do
        expect {
          described_class.find_with_token(access_token:)
        }.to raise_error(TeachingRecordSystem::ApiError, "Unauthorized: Access token is invalid or expired (HTTP 401)")
      end
    end

    context "when timeout occurs" do
      before do
        stub_request(:get, "#{base_url}/v3/person")
          .with(
            headers: {
              "Authorization" => "Bearer #{access_token}",
              "X-Api-Version" => "Next",
            },
            query: { "include" => "PreviousNames" },
          )
          .to_timeout
      end

      it "raises Timeout::Error" do
        expect {
          described_class.find_with_token(access_token:)
        }.to raise_error(TeachingRecordSystem::TimeoutError)
      end
    end

    context "when server error (500)" do
      before do
        stub_request(:get, "#{base_url}/v3/person")
          .with(
            headers: {
              "Authorization" => "Bearer #{access_token}",
              "X-Api-Version" => "Next",
            },
            query: { "include" => "PreviousNames" },
          )
          .to_return(status: 500, body: "Internal Server Error")
      end

      it "raises ApiError with 500" do
        expect {
          described_class.find_with_token(access_token:)
        }.to raise_error(TeachingRecordSystem::ApiError, "Teaching Record System server error (HTTP 500)")
      end
    end
  end
end
