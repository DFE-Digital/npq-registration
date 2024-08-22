require "rails_helper"

RSpec.describe QualifiedTeachersAPISender do
  let(:user) { create(:user, trn: "1234567") }
  let(:course) { create(:course, :senior_leadership) }
  let(:declaration) { create(:declaration, :completed, user:, course:) }
  let(:participant_outcome) { create(:participant_outcome, declaration:, completion_date: Time.zone.local(2023, 2, 20, 17, 30, 0).rfc3339) }
  let(:params) do
    {
      participant_outcome_id: participant_outcome.id,
    }
  end

  subject(:service) do
    described_class.new(params)
  end

  describe "validations" do
    context "when the participant outcome id is missing" do
      let(:params) { { participant_outcome_id: nil } }

      it { expect(service).to have_error(:participant_outcome_id, :blank, "The property '#/missing_participant_outcome_id' must be present") }
    end

    context "when the participant outcome id is an invalid value" do
      let(:params) { { participant_outcome_id: SecureRandom.uuid  } }

      it { expect(service).to have_error(:participant_outcome, :blank, "There's no participant outcome for the given ID") }
    end

    context "when the participant outcome has already been successfully sent to the API" do
      let(:params) { { participant_outcome_id: create(:participant_outcome, declaration:, qualified_teachers_api_request_successful: true).id } }

      it { expect(service).to have_error(:participant_outcome, :already_successfully_sent_to_api, "This participant outcome has already been successfully submitted to Qualified Teachers API (TRA)") }
    end

    context "when the participant outcome has already been unsuccessfully sent to the API" do
      let(:params) { { participant_outcome_id: create(:participant_outcome, declaration:, qualified_teachers_api_request_successful: false).id } }

      it { expect(service).to have_error(:participant_outcome, :already_unsuccessfully_sent_to_api, "This participant outcome has already been unsuccessfully submitted to Qualified Teachers API (TRA)") }
    end
  end

  describe "#send" do
    let(:trn) { participant_outcome.declaration.user.trn }
    let(:request_body) do
      {
        completionDate: participant_outcome.completion_date.to_s,
        qualificationType: participant_outcome.declaration.qualification_type,
      }
    end

    before do
      stub_request(:put, "https://qualified-teachers-api.example.com/v2/npq-qualifications?trn=1234567")
        .with(
          body: request_body,
        )
        .to_return(status: 204, body: "", headers: {})
    end

    describe "when no exception is raised" do
      before { allow_any_instance_of(QualifiedTeachers::Client).to receive(:send_record).with({ trn:, request_body: }).and_call_original }

      it "updates sent to qualified teachers api at" do
        expect { service.send_record }.to(change { participant_outcome.reload.sent_to_qualified_teachers_api_at })
      end

      it "creates a new participant outcome api request" do
        expect { service.send_record }.to change { participant_outcome.reload.participant_outcome_api_requests.size }.from(0).to(1)
      end

      it "updates qualified teachers api request successful" do
        expect { service.send_record }.to change { participant_outcome.reload.qualified_teachers_api_request_successful? }.from(false).to(true)
      end

      it "returns the participant outcome" do
        expect(service.send_record).to eq(participant_outcome)
      end

      context "with failed outcome" do
        let(:participant_outcome) { create(:participant_outcome, :failed, declaration:) }
        let(:request_body) do
          {
            completionDate: nil,
            qualificationType: participant_outcome.declaration.qualification_type,
          }
        end

        it "sends a request without a completion date" do
          expect { service.send_record }.to change { participant_outcome.reload.qualified_teachers_api_request_successful? }.from(false).to(true)
        end
      end

      context "with voided outcome" do
        let(:participant_outcome) { create(:participant_outcome, :voided, declaration:) }
        let(:request_body) do
          {
            completionDate: nil,
            qualificationType: participant_outcome.declaration.qualification_type,
          }
        end

        it "sends a request without a completion date" do
          expect { service.send_record }.to change { participant_outcome.reload.qualified_teachers_api_request_successful? }.from(false).to(true)
        end
      end
    end

    describe "when an exception is raised" do
      before { allow_any_instance_of(QualifiedTeachers::Client).to receive(:send_record).with({ trn:, request_body: }).and_raise(StandardError) }

      it "does nothing" do
        expect(Sentry).to receive(:capture_exception)

        expect { service.send_record }.to raise_error(StandardError)
      end
    end
  end
end
