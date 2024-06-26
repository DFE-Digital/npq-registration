require "rails_helper"

RSpec.describe "Declaration endpoints", type: :request do
  let(:current_lead_provider) { create(:lead_provider) }
  let(:query) { Declarations::Query }
  let(:serializer) { API::DeclarationSerializer }
  let(:serializer_version) { :v1 }

  def create_resource(**attrs)
    if attrs[:user]
      attrs[:application] = create(:application, user: attrs[:user])
      attrs.delete(:user)
    end

    create(:declaration, **attrs)
  end

  describe "GET /api/v1/participant-declarations" do
    let(:path) { api_v1_declarations_path }
    let(:resource_id_key) { :ecf_id }

    it_behaves_like "an API index endpoint"
    it_behaves_like "an API index endpoint with pagination"
    it_behaves_like "an API index endpoint with filter by updated_since"
    it_behaves_like "an API index endpoint with filter by participant_id"
  end

  describe "GET /api/v1/participant-declarations.csv" do
    let(:serializer) { API::DeclarationsCsvSerializer }
    let(:mock_serializer) { instance_double(API::DeclarationsCsvSerializer, serialize: nil) }
    let(:path) { api_v1_declarations_path(format: :csv) }
    let(:resource_id_key) { :ecf_id }
    let(:csv_serializer_version) { :v1 }

    it_behaves_like "an API index Csv endpoint", returns_headers_on_empty: false
  end

  describe "GET /api/v1/participant-declarations/:ecf_id" do
    let(:resource) { create(:declaration, lead_provider: current_lead_provider) }
    let(:resource_id) { resource.ecf_id }

    def path(id = nil)
      api_v1_declaration_path(id)
    end

    it_behaves_like "an API show endpoint"
  end

  describe "PUT /api/v1/participant-declarations/:ecf_id/void" do
    let(:resource) { create(:declaration, lead_provider: current_lead_provider) }
    let(:resource_id) { resource.ecf_id }
    let(:service) { Declarations::Void }
    let(:action) { :void }
    let(:service_args) { { declaration: resource } }

    def path(id = nil)
      void_api_v1_declaration_path(ecf_id: id)
    end

    it_behaves_like "an API update endpoint"
  end

  describe("create") do
    before { api_post(api_v1_declarations_path) }

    specify { expect(response).to(be_method_not_allowed) }
  end
end
