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
      {
        data: {
          id: "7acaabaf-71ec-4836-be82-5ae59863fdf7",
          type: "npq-participant",
          attributes: {
            full_name: "John Doe 163",
            teacher_reference_number: "1234567",
            updated_at: "2024-06-25T12:01:30Z",
            npq_enrolments: [{
              email: "john.doe.163@dare-beier.example",
              course_identifier: "npq-early-headship-coaching-offer",
              schedule_identifier: "npq-ehco-december",
              cohort: "2023",
              npq_application_id: "58b364cb-1633-41d5-8d1d-eab55bedc986",
              eligible_for_funding: true,
              training_status: "active",
              school_urn: "495078",
              targeted_delivery_funding_eligibility: false,
              deferral: nil,
              withdrawl: nil,
              created_at: "2024-06-25T12:01:30Z",
              funded_place: true,
            }],
            participant_id_changes: [{
              from_participant_id: "2e61008e-df8d-4d70-8ca2-e0680193f391",
              to_participant_id: "7acaabaf-71ec-4836-be82-5ae59863fdf7",
              changed_at: "2024-06-25T12:01:30Z",
            }],
          },
        },
      }
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
          example[:data][:attributes][:npq_enrolments][0][:deferral] = {
            reason: "bereavement",
            date: "2024-06-25T12:01:30Z",
          }
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
      let(:attributes) { { course_identifier: course.identifier, reason: Participants::Withdraw::WITHDRAWL_REASONS.sample } }
      let(:invalid_attributes) { { course_identifier: "invalid" } }
      let(:response_example) do
        base_response_example.tap do |example|
          example[:data][:attributes][:npq_enrolments][0][:training_status] = "withdrawn"
          example[:data][:attributes][:npq_enrolments][0][:withdrawl] = {
            reason: "change-in-developmental-or-personal-priorities",
            date: "2024-06-25T12:01:30Z",
          }
        end
      end
    end
  end
end
