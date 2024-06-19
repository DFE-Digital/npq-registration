require "rails_helper"

RSpec.describe "Application endpoints", type: :request do
  let(:current_lead_provider) { create(:lead_provider) }
  let(:query) { Applications::Query }
  let(:serializer) { API::ApplicationSerializer }
  let(:serializer_version) { :v3 }

  describe "GET /api/v3/applications/:id" do
    let(:resource) { create(:application, lead_provider: current_lead_provider) }
    let(:resource_id) { resource.ecf_id }

    def path(id = nil)
      api_v3_application_path(id)
    end

    it_behaves_like "an API show endpoint"
  end

  describe "GET /api/v3/npq-applications" do
    let(:path) { api_v3_applications_path }
    let(:resource_id_key) { :ecf_id }

    def create_resource(**attrs)
      create(:application, **attrs)
    end

    it_behaves_like "an API index endpoint"
    it_behaves_like "an API index endpoint with pagination"
    it_behaves_like "an API index endpoint with filter by cohort"
    it_behaves_like "an API index endpoint with filter by updated_since"
    it_behaves_like "an API index endpoint with filter by participant_id"
  end

  describe "POST /api/v3/npq-applications/:ecf_id/accept" do
    let(:cohort) { create(:cohort, :current) }
    let(:course_group) { CourseGroup.find_by(name: "leadership") || create(:course_group, name: "leadership") }
    let(:course) { create(:course, :sl, course_group:) }
    let(:schedule) { create(:schedule, :npq_leadership_autumn, course_group:, cohort:) }

    let(:application) { create(:application, cohort:, course:, lead_provider: current_lead_provider) }
    let(:application_id) { application.ecf_id }

    def path(id = nil)
      accept_api_v3_application_path(id)
    end

    before { schedule }

    it_behaves_like "an API accept application endpoint"
  end

  describe "POST /api/v3/npq-applications/:ecf_id/reject" do
    let(:service_class) { Applications::Reject }

    def path(id = nil)
      reject_api_v3_application_path(id)
    end

    it_behaves_like "an API reject application endpoint"
  end

  describe "PUT /api/v3/npq-applications/:ecf_id/change-funded-place" do
    let(:application) { create(:application, :eligible_for_funded_place, lead_provider: current_lead_provider) }
    let(:application_id) { application.ecf_id }

    def path(id = nil)
      change_funded_place_api_v3_application_path(id)
    end

    it_behaves_like "an API change application funded place endpoint"
  end
end
