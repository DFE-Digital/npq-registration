require "rails_helper"

RSpec.describe Dqt::V1::Teacher do
  subject { described_class }

  let(:trn) { "1001000" }
  let(:incorrect_trn) { "1001009" }
  let(:birthdate) { Date.new(1987, 12, 13) }
  let(:nino) { "AB123456D" }
  let(:active_alert) { true }

  let(:response_hash) do
    {
      "trn": trn,
      "ni_number": "AB123456D",
      "name": "Mostly Populated",
      "dob": "1987-12-13",
      "active_alert": active_alert,
      "state_name": "Active",
    }
  end

  let(:stub_api_request) do
    stub_request(:get, "https://dqt-api.example.com/v1/teachers/#{trn}?birthdate=#{birthdate}")
      .with(
        headers: {
          "Accept" => "*/*",
          "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
          "Authorization" => "Bearer test-apikey",
          "User-Agent" => "Ruby",
        },
      )
      .to_return(status: 200, body: response_hash.to_json, headers: {})
  end

  let(:stub_api_404_request) do
    stub_request(:get, "https://dqt-api.example.com/v1/teachers/#{trn}?birthdate=#{birthdate}")
      .with(
        headers: {
          "Accept" => "*/*",
          "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
          "Authorization" => "Bearer test-apikey",
          "User-Agent" => "Ruby",
        },
      )
      .to_return(status: 404, body: nil, headers: {})
  end

  let(:stub_api_different_record_request) do
    stub_request(:get, "https://dqt-api.example.com/v1/teachers/#{incorrect_trn}?birthdate=#{birthdate}&nino=#{nino}")
      .with(
        headers: {
          "Accept" => "*/*",
          "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
          "Authorization" => "Bearer test-apikey",
          "User-Agent" => "Ruby",
        },
      )
      .to_return(status: 200, body: response_hash.to_json, headers: {})
  end

  describe ".find" do
    it "returns teacher record" do
      stub_api_request

      expect(Rails.logger).to receive(:info).with("DQT API request started")
      expect(Rails.logger).to receive(:info).with("DQT API response: 200")

      record = subject.find(trn:, birthdate:)

      expect(record["trn"]).to eq(trn)
      expect(record["active_alert"]).to be(true)

      expect(record["ni_number"]).to eq("AB123456D")
      expect(record["name"]).to eq("Mostly Populated")
      expect(record["dob"]).to eq("1987-12-13")
      expect(record["state_name"]).to eq("Active")
    end

    context "when record does not exist" do
      it "returns nil" do
        stub_api_404_request

        expect(Rails.logger).to receive(:info).with("DQT API request started")
        expect(Rails.logger).to receive(:info).with("DQT API response: 404")

        record = subject.find(trn:, birthdate:)

        expect(record).to be_nil
      end
    end

    context "with incorrect trn but correct nino" do
      let(:active_alert) { false }

      it "returns correct record" do
        stub_api_different_record_request

        expect(Rails.logger).to receive(:info).with("DQT API request started")
        expect(Rails.logger).to receive(:info).with("DQT API response: 200")

        record = subject.find(trn: incorrect_trn, birthdate:, nino:)

        expect(record["trn"]).to eql(trn)
        expect(record["active_alert"]).to be(false)
      end
    end
  end
end
