require "rails_helper"

RSpec.describe Services::ParticipantValidator do
  let(:trn) { rand(1_000_000..9_999_999).to_s }
  let(:full_name) { "Jane Doe" }
  let(:date_of_birth) { rand(60.years.ago..20.years.ago).to_date }
  let(:national_insurance_number) { "AB123456C" }

  subject do
    described_class.new(
      trn:,
      full_name:,
      date_of_birth:,
      national_insurance_number:,
    )
  end

  describe "#call" do
    context "when matching trn found" do
      let(:body) do
        {
          data: {
            attributes: {
              trn:,
              qts: true,
              active_alert: false,
            },
          },
        }
      end

      before do
        stub_request(:post,
                     "https://ecf-app.gov.uk/api/v1/participant-validation")
        .with(
          headers: {
            "Authorization" => "Bearer ECFAPPBEARERTOKEN",
          },
          body: {
            trn:,
            date_of_birth: date_of_birth.iso8601,
            full_name:,
            nino: national_insurance_number,
          },
        )
        .to_return(status: 200, body: body.to_json, headers: {})
      end

      it "returns record with matching trn" do
        expect(subject.call.trn).to eql(trn)
        expect(subject.call.active_alert).to be_falsey
      end
    end

    context "when different trn found by fuzzy matching" do
      let(:body) do
        {
          data: {
            attributes: {
              trn: (trn.to_i + 1).to_s,
              qts: true,
              active_alert: false,
            },
          },
        }
      end

      before do
        stub_request(:post,
                     "https://ecf-app.gov.uk/api/v1/participant-validation")
        .with(
          headers: {
            "Authorization" => "Bearer ECFAPPBEARERTOKEN",
          },
          body: {
            trn:,
            date_of_birth: date_of_birth.iso8601,
            full_name:,
            nino: national_insurance_number,
          },
        )
        .to_return(status: 200, body: body.to_json, headers: {})
      end

      it "returns record with diffrent trn" do
        expect(subject.call.trn).to be_present
        expect(subject.call.trn).not_to eql(trn)
        expect(subject.call.active_alert).to be_falsey
      end
    end

    context "when no record could be found" do
      before do
        stub_request(:post,
                     "https://ecf-app.gov.uk/api/v1/participant-validation")
        .with(
          headers: {
            "Authorization" => "Bearer ECFAPPBEARERTOKEN",
          },
          body: {
            trn:,
            date_of_birth: date_of_birth.iso8601,
            full_name:,
            nino: national_insurance_number,
          },
        )
        .to_return(status: 404, body: "", headers: {})
      end

      it "returns nil" do
        expect(subject.call).to be_nil
      end
    end
  end
end
