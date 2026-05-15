require "rails_helper"

RSpec.describe TeachingRecordSystem::ActivateTrnAllocation do
  let(:activation_url) { "#{ENV.fetch("TRS_API_URL")}/v3/trn-request/activate" }
  let(:trn_request_url) { "#{ENV.fetch("TRS_API_URL")}/v3/trn-request" }
  let(:access_token) { "VALIDTOKEN" }
  let(:headers) { { "Content-Type" => "application/json" } }

  let :activation_body do
    trn_request_body.merge("status" => "Completed", "trn" => "1234567")
  end

  let :trn_request_body do
    {
      "requestId" => SecureRandom.uuid,
      "status" => "Dormant",
      "trn" => nil,
      "potentialDuplicate" => false,
      "accessYourTeachingQualificationsLink" => "string",
    }
  end

  let :stub_trn_request do
    stub_request(:get, trn_request_url)
      .with(headers: { "Authorization" => "Bearer #{access_token}",
                       "X-Api-Version" => "20260416" })
      .to_return(status: [200, "Success"], headers:, body: trn_request_body.to_json)
  end

  let :stub_activation do
    stub_request(:put, activation_url)
      .with(headers: { "Authorization" => "Bearer #{access_token}",
                       "X-Api-Version" => "20260416" })
  end

  before { stub_trn_request }

  describe ".activate!" do
    subject { described_class.activate!(access_token) }

    before do
      stub_activation
        .to_return(status: [200, "Success"], headers:, body: activation_body.to_json)
    end

    it { is_expected.to eq "1234567" }
  end

  describe "#trn_request" do
    subject(:make_api_call) { described_class.new(access_token).trn_request }

    context "with valid access token" do
      it { is_expected.to eq trn_request_body }
    end

    context "without dormant trn request" do
      before do
        stub_request(:get, trn_request_url)
          .with(headers: { "Authorization" => "Bearer #{access_token}",
                           "X-Api-Version" => "20260416" })
          .to_return(status: [404, "Resource Not Found"], headers:)
      end

      it "raises an exception" do
        expect { make_api_call }
          .to raise_exception(described_class::NoTrnRequestToActivate)
      end
    end

    context "without valid access token" do
      before do
        stub_request(:get, trn_request_url)
          .with(headers: { "Authorization" => "Bearer #{access_token}",
                           "X-Api-Version" => "20260416" })
          .to_return(status: [401, "Unauthorized"], headers:)
      end

      it "raises an exception" do
        expect { make_api_call }.to raise_exception(Faraday::UnauthorizedError)
      end
    end

    context "with server error" do
      before do
        stub_request(:get, trn_request_url)
          .with(headers: { "Authorization" => "Bearer #{access_token}",
                           "X-Api-Version" => "20260416" })
          .to_return(status: [500, "Internal Server Error"], headers:)
      end

      it "raises an exception" do
        expect { make_api_call }.to raise_exception(Faraday::ServerError)
      end
    end
  end

  describe "#activate!" do
    subject(:make_api_call) { described_class.new(access_token).activate! }

    context "with valid access token" do
      before do
        stub_activation
          .to_return(status: [200, "Success"], headers:, body: activation_body.to_json)
      end

      it { is_expected.to eq "1234567" }
    end

    context "with valid access token when already activated" do
      before do
        stub_activation
          .to_return(status: [204, "No Content"], headers:, body: activation_body.to_json)
      end

      it { is_expected.to be_nil }
    end

    context "with pending trn request" do
      before do
        stub_activation
          .to_return(status: [200, "Success"],
                     headers:,
                     body: activation_body.merge("status" => "Pending").to_json)
      end

      it { is_expected.to be_nil }
    end

    context "without pending trn request" do
      let :stub_trn_request do
        stub_request(:get, trn_request_url)
          .with(headers: { "Authorization" => "Bearer #{access_token}",
                           "X-Api-Version" => "20260416" })
          .to_return(status: [404, "Resource not found"], headers:, body: nil)
      end

      it "raises NoTrnRequestToActivate" do
        expect { make_api_call }
          .to raise_exception(described_class::NoTrnRequestToActivate)
      end
    end

    context "with invalid access token" do
      before do
        stub_activation
          .to_return(status: [401, "Unauthorized"], headers:)
      end

      let(:access_token) { "INVALIDTOKEN" }

      it "raises an exception" do
        expect { make_api_call }.to raise_exception(Faraday::UnauthorizedError)
      end
    end

    context "with server error" do
      before do
        stub_activation
          .to_return(status: [500, "Internal Server Error"], headers:)
      end

      it "raises an exception" do
        expect { make_api_call }.to raise_exception(Faraday::ServerError)
      end
    end
  end
end
