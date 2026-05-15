require "rails_helper"

RSpec.describe TeachingRecordSystem::RefreshAccessToken do
  let(:api_url) { "#{ENV.fetch("TEACHER_AUTH_DOMAIN")}oauth2/token" }
  let(:refresh_token) { "VALIDTOKEN" }
  let(:headers) { { "Content-Type" => "application/json" } }

  let :request_params do
    {
      grant_type: "refresh_token",
      refresh_token:,
      client_id: ENV["TEACHER_AUTH_CLIENT_ID"],
      client_secret: ENV["TEACHER_AUTH_CLIENT_SECRET"],
    }
  end

  let :response_body do
    {
      "access_token" => "REDACTED-NEW-ACCESS",
      "token_type" => "Bearer",
      "expires_in" => 3599,
      "scope" => "email openid offline_access profile teaching_record",
      "id_token" => "REDACTED-NEW-ID",
      "refresh_token" => "REDACTED-NEW-REFRESH",
    }
  end

  let :stub_api_request do
    stub_request(:post, api_url)
          .with(headers: { "Content-Type" => "application/x-www-form-urlencoded" },
                body: request_params)
          .to_return(status: [200, "Success"],
                     headers:,
                     body: response_body.to_json)
  end

  describe ".refresh!" do
    subject { described_class.refresh!(refresh_token) }

    before { stub_api_request }

    it { is_expected.to eq %w[REDACTED-NEW-ACCESS REDACTED-NEW-REFRESH] }
  end

  describe "#refresh!" do
    subject(:make_api_call) { described_class.new(refresh_token).refresh! }

    context "with valid refresh token" do
      before { stub_api_request }

      it { is_expected.to eq %w[REDACTED-NEW-ACCESS REDACTED-NEW-REFRESH] }
    end

    context "with invalid refresh token" do
      before do
        stub_request(:post, api_url)
        .with(headers: { "Content-Type" => "application/x-www-form-urlencoded" },
              body: request_params)
        .to_return(status: [401, "Unauthorized"], headers:)
      end

      let(:refresh_token) { "INVALIDTOKEN" }

      it "raises an exception" do
        expect { make_api_call }.to raise_exception(Faraday::UnauthorizedError)
      end
    end

    context "with server error" do
      before do
        stub_request(:post, api_url)
        .with(headers: { "Content-Type" => "application/x-www-form-urlencoded" },
              body: request_params)
        .to_return(status: [500, "Internal Server Error"], headers:)
      end

      it "raises an exception" do
        expect { make_api_call }.to raise_exception(Faraday::ServerError)
      end
    end
  end

  describe "#access_token" do
    subject { described_class.new(refresh_token).access_token }

    before { stub_api_request }

    it { is_expected.to eq "REDACTED-NEW-ACCESS" }
  end

  describe "#refresh_token" do
    subject { described_class.new(refresh_token).refresh_token }

    before { stub_api_request }

    it { is_expected.to eq "REDACTED-NEW-REFRESH" }
  end
end
