require "rails_helper"
require "swagger_helper"

RSpec.describe "NPQ Participants endpoint", type: :request, openapi_spec: "v3/swagger.yaml" do
  include_context "with authorization for api doc request"

  let(:course) { create(:course, :ehco) }
  let(:cohort) { create(:cohort, :current) }
  let(:schedule) { create(:schedule, :npq_ehco_december, cohort:) }
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
           funded_place: true)
  end
  let!(:participant) { application.user }

  it_behaves_like "an API index endpoint documentation",
                  "/api/v3/participants/npq",
                  "NPQ Participants",
                  "NPQ participants",
                  "#/components/schemas/ListParticipantsFilter",
                  "#/components/schemas/ParticipantsResponse"

  it_behaves_like "an API show endpoint documentation",
                  "/api/v3/participants/npq/{id}",
                  "NPQ Participants",
                  "NPQ participant",
                  "#/components/schemas/ParticipantResponse" do
    let(:resource) { participant }
  end

  describe "update actions" do
    let(:base_response_example) do
      extract_swagger_example(schema: "#/components/schemas/ParticipantResponse", version: :v3)
    end

    it_behaves_like "an API update endpoint documentation",
                    "/api/v3/participants/npq/{id}/resume",
                    "NPQ Participants",
                    "Resume an NPQ participant",
                    "The NPQ participant being resumed",
                    "#/components/schemas/ParticipantResponse",
                    "#/components/schemas/ParticipantResumeRequest" do
      before { application.withdrawn! }

      let(:resource) { participant }
      let(:type) { "participant-resume" }
      let(:attributes) { { course_identifier: course.identifier } }
      let(:invalid_attributes) { { course_identifier: "invalid" } }
      let(:response_example) do
        base_response_example.tap do |example|
          example[:data][:attributes][:npq_enrolments][0][:training_status] = "active"
          example[:data][:attributes][:npq_enrolments][0][:deferral] = nil
          example[:data][:attributes][:npq_enrolments][0][:withdrawal] = nil
        end
      end
    end

    it_behaves_like "an API update endpoint documentation",
                    "/api/v3/participants/npq/{id}/defer",
                    "NPQ Participants",
                    "Defer an NPQ participant",
                    "The NPQ participant being deferred",
                    "#/components/schemas/ParticipantResponse",
                    "#/components/schemas/ParticipantDeferRequest" do
      let(:resource) { participant }
      let(:type) { "participant-defer" }
      let(:attributes) { { course_identifier: course.identifier, reason: Participants::Defer::DEFERRAL_REASONS.sample } }
      let(:invalid_attributes) { { course_identifier: "invalid" } }
      let(:response_example) do
        base_response_example.tap do |example|
          example[:data][:attributes][:npq_enrolments][0][:training_status] = "deferred"
          example[:data][:attributes][:npq_enrolments][0][:withdrawal] = nil
        end
      end
    end

    it_behaves_like "an API update endpoint documentation",
                    "/api/v3/participants/npq/{id}/withdraw",
                    "NPQ Participants",
                    "Withdraw an NPQ participant",
                    "The NPQ participant being withdrawn",
                    "#/components/schemas/ParticipantResponse",
                    "#/components/schemas/ParticipantWithdrawRequest" do
      let(:resource) { participant }
      let(:type) { "participant-withdraw" }
      let(:attributes) { { course_identifier: course.identifier, reason: Participants::Withdraw::WITHDRAWAL_REASONS.sample } }
      let(:invalid_attributes) { { course_identifier: "invalid" } }
      let(:response_example) do
        base_response_example.tap do |example|
          example[:data][:attributes][:npq_enrolments][0][:training_status] = "withdrawn"
          example[:data][:attributes][:npq_enrolments][0][:deferral] = nil
        end
      end
    end
  end
end
