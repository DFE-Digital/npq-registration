require "rails_helper"

RSpec.describe ParticipantValidator do
  subject do
    described_class.new(
      trn:,
      full_name:,
      date_of_birth:,
      national_insurance_number:,
    ).call
  end

  let(:trn) { rand(1_000_000..9_999_999).to_s }
  let(:full_name) { "Jane Doe" }
  let(:date_of_birth) { rand(60.years.ago..20.years.ago).to_date }
  let(:national_insurance_number) { "AB123456C" }

  describe "#call" do
    context "when ecf_api_disabled is false" do
      before { allow(Feature).to receive(:ecf_api_disabled?).and_return(false) }

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
          expect(subject.trn).to eql(trn)
          expect(subject.active_alert).to be_falsey
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
          expect(subject.trn).to be_present
          expect(subject.trn).not_to eql(trn)
          expect(subject.active_alert).to be_falsey
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
          expect(subject).to be_nil
        end
      end
    end

    context "when ecf_api_disabled is true" do
      let(:total_matched) { 3 }
      let(:body) do
        {
          "trn" => trn,
          "active_alert" => true,
        }
      end
      let(:dqt_result) do
        OpenStruct.new(
          dqt_record: Dqt::TeacherRecord.new(body),
          total_matched:,
        )
      end

      before do
        allow(Feature).to receive(:ecf_api_disabled?).and_return(true)

        service = instance_double(Dqt::RecordCheck)
        allow(service).to receive(:call).and_return(dqt_result)

        allow(Dqt::RecordCheck).to receive(:new)
          .with(
            trn:,
            full_name:,
            date_of_birth: date_of_birth.iso8601,
            nino: national_insurance_number,
            check_first_name_only: true,
          ).and_return(service)
      end

      context "when total_matched is 3" do
        let(:total_matched) { 3 }

        it "returns teacher record" do
          expect(subject.trn).to eq(trn)
          expect(subject.active_alert).to be(true)
        end
      end

      context "when total_matched is 2" do
        let(:total_matched) { 2 }

        it "returns nil" do
          expect(subject).to be_nil
        end
      end
    end
  end
end
