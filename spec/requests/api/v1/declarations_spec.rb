require "rails_helper"

RSpec.describe "Declaration endpoints", type: :request do
  let(:current_lead_provider) { create(:lead_provider) }
  let(:query) { Declarations::Query }
  let(:serializer) { API::DeclarationSerializer }
  let(:serializer_version) { :v1 }

  describe "GET /api/v1/participant-declarations" do
    let(:path) { api_v1_declarations_path }
    let(:resource_id_key) { :ecf_id }

    def create_resource(**attrs)
      if attrs[:user]
        attrs[:application] = create(:application, user: attrs[:user])
        attrs.delete(:user)
      end

      create(:declaration, **attrs)
    end

    it_behaves_like "an API index endpoint"
    it_behaves_like "an API index endpoint with pagination"
    it_behaves_like "an API index endpoint with filter by updated_since"
    it_behaves_like "an API index endpoint with filter by participant_id"
  end

  describe "GET /api/v1/declarations/:id" do
    let(:resource) { create(:declaration, lead_provider: current_lead_provider) }
    let(:resource_id) { resource.ecf_id }

    def path(id = nil)
      api_v1_declaration_path(id)
    end

    it_behaves_like "an API show endpoint"
  end

  describe("create") do
    before { api_post(api_v1_declarations_path) }

    specify { expect(response).to(be_method_not_allowed) }
  end

  describe("void") do
    before { api_put(api_v1_declaration_void_path(123)) }

    specify { expect(response).to(be_method_not_allowed) }
  end
end
