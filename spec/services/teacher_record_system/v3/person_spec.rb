require "rails_helper"

RSpec.describe TeacherRecordSystem::V3::Person do
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
          .with(headers: {
            "Authorization" => "Bearer #{access_token}",
            "X-Api-Version" => "Next",
          })
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
          .with(headers: {
            "Authorization" => "Bearer #{access_token}",
            "X-Api-Version" => "Next",
          })
          .to_return(status: 401)
      end

      it "returns nil" do
        record = described_class.find_with_token(access_token:)
        expect(record).to be_nil
      end
    end

    context "when timeout occurs on all attempts" do
      before do
        stub_request(:get, "#{base_url}/v3/person")
          .with(headers: {
            "Authorization" => "Bearer #{access_token}",
            "X-Api-Version" => "Next",
          })
          .to_timeout
      end

      it "retries once then raises TimeoutError" do
        expect {
          described_class.find_with_token(access_token:)
        }.to raise_error(TeacherRecordSystem::TimeoutError)
      end
    end

    context "when timeout occurs once then succeeds" do
      before do
        stub_request(:get, "#{base_url}/v3/person")
          .with(headers: {
            "Authorization" => "Bearer #{access_token}",
            "X-Api-Version" => "Next",
          })
          .to_timeout.then
          .to_return(status: 200, body: teaching_record_response.to_json)
      end

      it "retries and returns successful result" do
        record = described_class.find_with_token(access_token:)

        expect(record["trn"]).to eq(trn)
        expect(record["firstName"]).to eq("Sarah")
      end
    end

    context "when retries is set to 0" do
      before do
        stub_request(:get, "#{base_url}/v3/person")
          .with(headers: {
            "Authorization" => "Bearer #{access_token}",
            "X-Api-Version" => "Next",
          })
          .to_timeout
      end

      it "raises TimeoutError immediately without retrying" do
        expect {
          described_class.find_with_token(access_token:, retries: 0)
        }.to raise_error(TeacherRecordSystem::TimeoutError)
      end
    end

    context "when server error (500)" do
      before do
        stub_request(:get, "#{base_url}/v3/person")
          .with(headers: {
            "Authorization" => "Bearer #{access_token}",
            "X-Api-Version" => "Next",
          })
          .to_return(status: 500, body: "Internal Server Error")
      end

      it "returns nil" do
        record = described_class.find_with_token(access_token:)
        expect(record).to be_nil
      end
    end
  end
end
