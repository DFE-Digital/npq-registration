require "rails_helper"
require "swagger_helper"

RSpec.describe "NPQ Participants endpoint", type: :request, openapi_spec: "v2/swagger.yaml" do
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
                  "/api/v2/participants/npq",
                  "NPQ Participants",
                  "NPQ participants",
                  "#/components/schemas/ListParticipantsFilter",
                  "#/components/schemas/ParticipantsResponse"

  it_behaves_like "an API show endpoint documentation",
                  "/api/v2/participants/npq/{id}",
                  "NPQ Participants",
                  "NPQ participant",
                  "#/components/schemas/ParticipantResponse" do
    let(:resource) { participant }
  end

  it_behaves_like "an API update endpoint documentation",
                  "/api/v2/participants/npq/{id}/resume",
                  "NPQ Participants",
                  "NPQ participant (resume)",
                  "#/components/schemas/ParticipantResponse",
                  "#/components/schemas/ParticipantResumeRequest" do
    before { application.withdrawn! }

    let(:resource) { participant }
    let(:action) { "participant-resume" }
    let(:attributes) { { course_identifier: course.identifier } }
    let(:invalid_attributes) { { course_identifier: "invalid" } }
  end

  it_behaves_like "an API update endpoint documentation",
                  "/api/v2/participants/npq/{id}/defer",
                  "NPQ Participants",
                  "NPQ participant (defer)",
                  "#/components/schemas/ParticipantResponse",
                  "#/components/schemas/ParticipantDeferRequest" do
    let(:resource) { participant }
    let(:action) { "participant-defer" }
    let(:attributes) { { course_identifier: course.identifier, reason: Participants::Defer::DEFERRAL_REASONS.sample } }
    let(:invalid_attributes) { { course_identifier: "invalid" } }
  end

  it_behaves_like "an API update endpoint documentation",
                  "/api/v2/participants/npq/{id}/withdraw",
                  "NPQ Participants",
                  "NPQ participant (withdraw)",
                  "#/components/schemas/ParticipantResponse",
                  "#/components/schemas/ParticipantWithdrawRequest" do
    let(:resource) { participant }
    let(:action) { "participant-withdraw" }
    let(:attributes) { { course_identifier: course.identifier, reason: Participants::Withdraw::WITHDRAWL_REASONS.sample } }
    let(:invalid_attributes) { { course_identifier: "invalid" } }
  end
end
