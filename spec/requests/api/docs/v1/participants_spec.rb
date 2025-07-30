require "rails_helper"
require "swagger_helper"

RSpec.describe "NPQ Participants endpoint", openapi_spec: "v1/swagger.yaml", skip: Rails.configuration.x.disable_legacy_api, type: :request do
  include_context "with authorization for api doc request"

  let(:course) { create(:course, :early_headship_coaching_offer) }
  let(:cohort) { create(:cohort, :current) }
  let(:schedule) { create(:schedule, :npq_ehco_december, cohort:) }
  let(:user) { create(:user, :with_verified_trn) }
  let(:application) do
    create(:application,
           :accepted,
           :with_declaration,
           :eligible_for_funded_place,
           :with_participant_id_change,
           lead_provider:,
           course:,
           cohort:,
           schedule:,
           user:,
           funded_place: true)
  end
  let!(:participant) { application.user }

  before do
    statement = create(:statement, cohort:, lead_provider:)
    create(:contract, statement:, course:)
  end

  it_behaves_like "an API index endpoint documentation",
                  "/api/v1/participants/npq",
                  "NPQ Participants",
                  "NPQ participants",
                  "#/components/schemas/ListParticipantsFilter",
                  "#/components/schemas/ParticipantsResponse"

  it_behaves_like "an API show endpoint documentation",
                  "/api/v1/participants/npq/{id}",
                  "NPQ Participants",
                  "NPQ participant",
                  "#/components/schemas/ParticipantResponse" do
    let(:resource) { participant }
  end

  describe "update actions" do
    let(:base_response_example) do
      extract_swagger_example(schema: "#/components/schemas/ParticipantResponse", version: :v1)
    end

    it_behaves_like "an API update endpoint documentation",
                    "/api/v1/participants/npq/{id}/resume",
                    "NPQ Participants",
                    "Resume an NPQ participant",
                    "The NPQ participant being resumed",
                    "#/components/schemas/ParticipantResponse",
                    "#/components/schemas/ParticipantResumeRequest" do
      before { application.withdrawn_training_status! }

      let(:resource) { participant }
      let(:type) { "participant-resume" }
      let(:attributes) { { course_identifier: course.identifier } }
      let(:invalid_attributes) { { course_identifier: "invalid" } }
    end

    it_behaves_like "an API update endpoint documentation",
                    "/api/v1/participants/npq/{id}/defer",
                    "NPQ Participants",
                    "Defer an NPQ participant",
                    "The NPQ participant being deferred",
                    "#/components/schemas/ParticipantResponse",
                    "#/components/schemas/ParticipantDeferRequest" do
      let(:resource) { participant }
      let(:type) { "participant-defer" }
      let(:attributes) { { course_identifier: course.identifier, reason: Participants::Defer::DEFERRAL_REASONS.sample } }
      let(:invalid_attributes) { { course_identifier: "invalid" } }
    end

    it_behaves_like "an API update endpoint documentation",
                    "/api/v1/participants/npq/{id}/withdraw",
                    "NPQ Participants",
                    "Withdraw an NPQ participant",
                    "The NPQ participant being withdrawn",
                    "#/components/schemas/ParticipantResponse",
                    "#/components/schemas/ParticipantWithdrawRequest" do
      let(:resource) { participant }
      let(:type) { "participant-withdraw" }
      let(:attributes) { { course_identifier: course.identifier, reason: Participants::Withdraw::WITHDRAWAL_REASONS.sample } }
      let(:invalid_attributes) { { course_identifier: "invalid" } }
    end

    it_behaves_like "an API update endpoint documentation",
                    "/api/v1/participants/npq/{id}/change-schedule",
                    "NPQ Participants",
                    "Notify that an NPQ participant is changing training schedule",
                    "The NPQ participant changing schedule",
                    "#/components/schemas/ParticipantResponse",
                    "#/components/schemas/ParticipantChangeScheduleRequest" do
      let(:resource) { participant }
      let(:type) { "participant-change-schedule" }
      let(:new_schedule) { create(:schedule, :npq_ehco_march, cohort:) }
      let(:attributes) { { schedule_identifier: new_schedule.identifier, course_identifier: course.identifier, cohort: application.cohort.start_year } }
      let(:invalid_attributes) { { schedule_identifier: "invalid", course_identifier: "invalid" } }
      let(:response_example) do
        base_response_example.tap do |example|
          example[:data][:attributes][:npq_courses][0] = course.identifier
          example[:data][:attributes][:funded_places][0][:npq_course] = course.identifier
        end
      end
    end
  end
end
