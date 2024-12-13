require "rails_helper"

RSpec.describe "Application endpoints", type: :request do
  let(:current_lead_provider) { create(:lead_provider) }
  let(:query) { Applications::Query }
  let(:serializer) { API::ApplicationSerializer }

  describe "GET /api/v2/applications/:id" do
    let(:resource) { create(:application, lead_provider: current_lead_provider) }
    let(:resource_id) { resource.ecf_id }

    def path(id = nil)
      api_v2_application_path(id)
    end

    it_behaves_like "an API show endpoint"
  end

  describe "GET /api/v2/npq-applications" do
    let(:path) { api_v2_applications_path }
    let(:resource_id_key) { :ecf_id }

    def create_resource(**attrs)
      create(:application, **attrs)
    end

    it_behaves_like "an API index endpoint"
    it_behaves_like "an API index endpoint with pagination"
    it_behaves_like "an API index endpoint with filter by cohort"
    it_behaves_like "an API index endpoint with filter by updated_since"
  end

  describe "GET /api/v2/npq-applications.csv" do
    let(:serializer) { API::ApplicationsCsvSerializer }
    let(:mock_serializer) { instance_double(API::ApplicationsCsvSerializer, serialize: nil) }
    let(:path) { api_v2_applications_path(format: :csv) }
    let(:resource_id_key) { :ecf_id }

    def create_resource(**attrs)
      create(:application, **attrs)
    end

    it_behaves_like "an API index Csv endpoint"
    it_behaves_like "an API index Csv endpoint with filter by cohort"
    it_behaves_like "an API index Csv endpoint with filter by updated_since"
  end

  describe "POST /api/v2/npq-applications/:ecf_id/accept" do
    let(:resource) { create(:application, lead_provider: current_lead_provider) }
    let(:resource_id) { resource.ecf_id }
    let(:service) { Applications::Accept }
    let(:action) { :accept }
    let(:attributes) { { funded_place: true } }
    let(:service_args) { { application: resource }.merge!(attributes) }

    def path(id = nil)
      accept_api_v2_application_path(ecf_id: id)
    end

    it_behaves_like "an API create on resource endpoint"
  end

  describe "POST /api/v2/npq-applications/:ecf_id/reject" do
    let(:resource) { create(:application, lead_provider: current_lead_provider) }
    let(:resource_id) { resource.ecf_id }
    let(:service) { Applications::Reject }
    let(:action) { :reject }
    let(:service_args) { { application: resource } }

    def path(id = nil)
      reject_api_v2_application_path(ecf_id: id)
    end

    it_behaves_like "an API create on resource endpoint"
  end

  describe "PUT /api/v2/npq-applications/:ecf_id/change-funded-place" do
    let(:resource) { create(:application, lead_provider: current_lead_provider) }
    let(:resource_id) { resource.ecf_id }
    let(:service) { Applications::ChangeFundedPlace }
    let(:action) { :change }
    let(:attributes) { { funded_place: false } }
    let(:service_args) { { application: resource }.merge!(attributes) }

    def path(id = nil)
      change_funded_place_api_v2_application_path(ecf_id: id)
    end

    it_behaves_like "an API update endpoint"
  end
end
