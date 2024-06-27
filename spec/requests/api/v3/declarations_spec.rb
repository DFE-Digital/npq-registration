require "rails_helper"

RSpec.describe "Declaration endpoints", type: :request do
  let(:current_lead_provider) { create(:lead_provider) }
  let(:query) { Declarations::Query }
  let(:serializer) { API::DeclarationSerializer }
  let(:serializer_version) { :v3 }

  def create_resource(**attrs)
    if attrs[:user]
      attrs[:application] = create(:application, user: attrs[:user])
      attrs.delete(:user)
    end

    create(:declaration, **attrs)
  end

  describe "GET /api/v3/participant-declarations" do
    let(:path) { api_v3_declarations_path }
    let(:resource_id_key) { :ecf_id }

    it_behaves_like "an API index endpoint"
    it_behaves_like "an API index endpoint with pagination"
    it_behaves_like "an API index endpoint with filter by updated_since"
    it_behaves_like "an API index endpoint with filter by participant_id"
    it_behaves_like "an API index endpoint with filter by cohort"
  end

  describe "GET /api/v3/participant-declarations/:ecf_id" do
    let(:resource) { create(:declaration, lead_provider: current_lead_provider) }
    let(:resource_id) { resource.ecf_id }

    def path(id = nil)
      api_v3_declaration_path(id)
    end

    it_behaves_like "an API show endpoint"
  end

  describe "PUT /api/v3/participant-declarations/:ecf_id/void" do
    let(:resource) { create(:declaration, lead_provider: current_lead_provider) }
    let(:resource_id) { resource.ecf_id }
    let(:service) { Declarations::Void }
    let(:action) { :void }
    let(:service_args) { { declaration: resource } }

    def path(id = nil)
      void_api_v3_declaration_path(ecf_id: id)
    end

    it_behaves_like "an API update endpoint"
  end

  describe "POST /api/v3/participant-declarations" do
    let(:path) { api_v3_declarations_path }

    let(:service) { Declarations::Create }
    let(:action) { :create_declaration }
    let(:lead_provider) { current_lead_provider }
    let(:cohort) { create(:cohort, :current) }
    let(:course_group) { CourseGroup.find_by(name: "leadership") || create(:course_group, name: "leadership") }
    let(:course) { create(:course, :sl, course_group:) }
    let!(:schedule) { create(:schedule, :npq_leadership_autumn, course_group:, cohort:) }
    let(:application) { create(:application, :accepted, cohort:, course:, lead_provider:) }
    let(:participant) { application.user }
    let!(:participant_id) { participant.ecf_id }
    let(:declaration_type) { "completed" }
    let(:declaration_date) { (schedule.applies_from + 1.day).rfc3339 }
    let(:course_identifier) { course.identifier }
    let(:has_passed) { true }
    let(:attributes) do
      {
        participant_id:,
        declaration_type:,
        declaration_date:,
        course_identifier:,
        has_passed:,
      }
    end
    let(:service_args) { { lead_provider: }.merge!(attributes) }
    let(:resource) { build(:declaration, lead_provider:) }
    let(:resource_id) { resource.ecf_id }
    let(:resource_name) { :declaration }

    it_behaves_like "an API create endpoint"
  end
end
