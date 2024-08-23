require "rails_helper"
require "swagger_helper"

RSpec.describe "NPQ Participant Outcomes endpoint", openapi_spec: "v3/swagger.yaml", type: :request do
  include_context "with authorization for api doc request"

  let(:course_group) { CourseGroup.find_by(name: "leadership") || create(:course_group, name: "leadership") }
  let(:course) { create(:course, :senior_leadership, course_group:) }
  let(:schedule) { create(:schedule, :npq_leadership_autumn, course_group:, cohort:) }
  let(:cohort) { create(:cohort, :current, funding_cap: true) }
  let(:application) do
    create(
      :application,
      course:,
      lead_provider:,
      cohort:,
      schedule:,
    )
  end
  let(:declaration) { create(:declaration, :completed, application:) }

  before { create(:participant_outcome, declaration:) }

  it_behaves_like "an API index endpoint documentation",
                  "/api/v3/participants/npq/outcomes",
                  "NPQ Participant Outcomes",
                  "NPQ Outcomes for all participants",
                  "#/components/schemas/ListParticipantOutcomesFilter",
                  "#/components/schemas/ParticipantOutcomesResponse"
end
