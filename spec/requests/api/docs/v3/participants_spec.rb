require "rails_helper"
require "swagger_helper"

RSpec.describe "NPQ Participants endpoint", type: :request, openapi_spec: "v3/swagger.yaml" do
  include_context "with authorization for api doc request"

  let(:course) { create(:course, :ehco) }
  let(:cohort) { create(:cohort, :current) }
  let(:schedule) { create(:schedule, :npq_ehco_december, cohort:) }
  let(:application) { create(:application, :eligible_for_funded_place, :with_participant_id_change, lead_provider:, course:, cohort:, schedule:, funded_place: true) }
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
                  "NPQ participants",
                  "#/components/schemas/ParticipantResponse" do
    let(:resource) { participant }
  end
end
