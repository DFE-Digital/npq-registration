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
      "state": 0,
      "state_name": "Active",
      "qualified_teacher_status": {
        "name": "Qualified teacher (trained)",
        "qts_date": "2021-07-05T00:00:00Z",
        "state": 0,
        "state_name": "Active",
      },
      "induction": {
        "start_date": "2021-07-01T00:00:00Z",
        "completion_date": "2021-07-05T00:00:00Z",
        "status": "Pass",
        "state": 0,
        "state_name": "Active",
      },
      "initial_teacher_training": {
        "programme_start_date": "2021-06-27T00:00:00Z",
        "programme_end_date": "2021-07-04T00:00:00Z",
        "programme_type": "Overseas Trained Teacher Programme",
        "result": "Pass",
        "subject1": "applied biology",
        "subject2": "applied chemistry",
        "subject3": "applied computing",
        "qualification": "BA (Hons)",
        "state": 0,
        "state_name": "Active",
      },
      "qualifications": [
        {
          "name": "Higher Education",
          "date_awarded": nil,
        },
        {
          "name": "NPQH",
          "date_awarded": "2021-07-05T00:00:00Z",
        },
        {
          "name": "Mandatory Qualification",
          "date_awarded": nil,
        },
        {
          "name": "HLTA",
          "date_awarded": nil,
        },
        {
          "name": "NPQML",
          "date_awarded": "2021-07-05T00:00:00Z",
        },
        {
          "name": "NPQSL",
          "date_awarded": "2021-07-04T00:00:00Z",
        },
        {
          "name": "NPQEL",
          "date_awarded": "2021-07-04T00:00:00Z",
        },
      ],
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

  describe ".validate_trn" do
    it "returns teacher record" do
      stub_api_request

      record = subject.validate_trn(trn:, birthdate:)

      expect(record["trn"]).to eq(trn)
      expect(record["active_alert"]).to be(true)
    end

    context "when record does not exist" do
      it "returns nil" do
        stub_api_404_request

        record = subject.validate_trn(trn:, birthdate:)

        expect(record).to be_nil
      end
    end

    context "with incorrect trn but correct nino" do
      let(:active_alert) { false }

      it "returns correct record" do
        stub_api_different_record_request

        record = subject.validate_trn(trn: incorrect_trn, birthdate:, nino:)

        expect(record["trn"]).to eql(trn)
        expect(record["active_alert"]).to be(false)
      end
    end
  end
end
