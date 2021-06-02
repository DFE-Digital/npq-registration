require "rails_helper"

RSpec.describe Services::DqtClient do
  let(:valid_response_body) do
    '{"data":{"id":"1234567","type":"dqt_record","attributes":{"teacher_reference_number":"1234567","full_name":"John Doe","date_of_birth":"1960-01-13","national_insurance_number":"AB123456C","qts_date":"1990-12-14","active_alert":false}}}'
  end

  before do
    stub_request(:get, "https://ecf-app.gov.uk/api/v1/dqt-records/1234567")
      .with(
        headers: {
          "Authorization" => "Bearer ECFAPPBEARERTOKEN",
        },
      )
      .to_return(status: 200, body: valid_response_body, headers: {})

    stub_request(:get, "https://ecf-app.gov.uk/api/v1/dqt-records/123456")
      .with(
        headers: {
          "Authorization" => "Bearer ECFAPPBEARERTOKEN",
        },
      )
      .to_return(status: 404, body: "", headers: {})
  end

  describe "#call" do
    subject { described_class.new(trn: "1234567") }

    it "returns DQT attributes" do
      attributes = subject.call

      expect(attributes["teacher_reference_number"]).to eql("1234567")
      expect(attributes["full_name"]).to eql("John Doe")
      expect(attributes["date_of_birth"]).to eql("1960-01-13")
      expect(attributes["national_insurance_number"]).to eql("AB123456C")
      expect(attributes["qts_date"]).to eql("1990-12-14")
      expect(attributes["active_alert"]).to eql(false)
    end

    context "when record does not exist" do
      subject { described_class.new(trn: "123456") }

      it "returns nil" do
        expect(subject.call).to be_nil
      end
    end
  end
end
