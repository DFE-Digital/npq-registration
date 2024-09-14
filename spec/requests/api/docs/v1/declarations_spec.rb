require "rails_helper"
require "swagger_helper"

RSpec.describe "Declarations endpoints", openapi_spec: "v1/swagger.yaml", type: :request do
  include_context "with authorization for api doc request"

  it_behaves_like "an API index Csv endpoint documentation",
                  "/api/v1/participant-declarations.csv",
                  "Participant declarations",
                  "Participant declarations",
                  "#/components/schemas/DeclarationsCsvResponse",
                  "#/components/schemas/ListParticipantDeclarationsFilter"

  it_behaves_like "an API index endpoint documentation",
                  "/api/v1/participant-declarations",
                  "Participant declarations",
                  "Participant declarations",
                  "#/components/schemas/ListParticipantDeclarationsFilter",
                  "#/components/schemas/ParticipantDeclarationsResponse"

  describe "single declarations" do
    let(:lead_provider) { create(:lead_provider) }
    let(:type) { "participant-declaration" } # check
    let(:application) { create(:application, :accepted, :with_declaration, lead_provider:) }
    let(:resource) { application.declarations.first }
    let(:base_response_example) do
      extract_swagger_example(schema: "#/components/schemas/ParticipantDeclarationResponse", version: :v1)
    end

    it_behaves_like "an API show endpoint documentation",
                    "/api/v1/participant-declarations/{id}",
                    "Participant declarations",
                    "Participant declarations",
                    "#/components/schemas/ParticipantDeclarationResponse"

    it_behaves_like "an API update endpoint documentation",
                    "/api/v1/participant-declarations/{id}/void",
                    "Participant declarations",
                    "Void a declaration",
                    "The participant declaration being voided",
                    "#/components/schemas/ParticipantDeclarationResponse" do
      let(:response_example) do
        base_response_example.tap do |example|
          example[:data][:attributes][:state] = "voided"
          example[:data][:attributes][:voided] = true
          example[:data][:attributes][:has_passed] = nil
        end
      end
    end
  end

  describe "create declarations" do
    let(:lead_provider) { create(:lead_provider) }
    let(:type) { "participant-declaration" } # check
    let(:cohort) { create(:cohort, :current) }
    let(:course_group) { CourseGroup.find_by(name: "leadership") }
    let(:course) { create(:course, :senior_leadership, course_group:) }
    let!(:schedule) { create(:schedule, :npq_leadership_autumn, course_group:, cohort:) }
    let(:application) { create(:application, :accepted, cohort:, course:, lead_provider:, schedule:) }
    let(:declaration_date) { schedule.applies_from + 1.day }
    let(:response_example) do
      extract_swagger_example(schema: "#/components/schemas/ParticipantDeclarationResponse", version: :v1)
    end
    let(:invalid_attributes) { { participant_id: "invalid" } }
    let(:attributes) do
      {
        participant_id: application.user.ecf_id,
        declaration_type: "started",
        declaration_date: declaration_date.rfc3339,
        course_identifier: course.identifier,
      }
    end

    before { travel_to(declaration_date) }

    it_behaves_like "an API create on resource endpoint documentation",
                    "/api/v1/participant-declarations",
                    "Participant declarations",
                    "Declare a participant has reached a milestone",
                    "The participant declaration being created",
                    "#/components/schemas/ParticipantDeclarationResponse",
                    "#/components/schemas/ParticipantDeclarationRequest"
  end
end
