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

  RSpec.shared_examples "changing a declaration by another lead provider" do
    let(:application) { create(:application, lead_provider: current_lead_provider) }
    let(:resource) { create(:declaration, application:, lead_provider: create(:lead_provider)) }

    before do
      Flipper.enable(Feature::LP_TRANSFERRED_DECLARATIONS_VISIBILITY)
      allow(service).to receive(:new).and_return(instance_double(service))
    end

    it "does not call the service" do
      expect(service).not_to receive(:new)
      api_put(path(resource_id))
    end

    it "returns 403 - forbidden" do
      api_put(path(resource_id))
      expect(response.status).to eq(403)
    end
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
    it_behaves_like "changing a declaration by another lead provider"
  end

  describe "PUT /api/v3/participant-declarations/:ecf_id/change-delivery-partner" do
    let(:cohort) { create(:cohort, :current) }

    let(:delivery_partner) { create(:delivery_partner, lead_providers: { cohort => current_ }) }
    let(:secondary_delivery_partner) { create(:delivery_partner, lead_providers: { cohort => current_lead_provider }) }
    let(:new_delivery_partner) { create(:delivery_partner, lead_providers: { cohort => current_lead_provider }) }
    let(:new_secondary_delivery_partner) { create(:delivery_partner, lead_providers: { cohort => current_lead_provider }) }
    let(:delivery_partner_id) { new_delivery_partner.ecf_id }
    let(:secondary_delivery_partner_id) { new_secondary_delivery_partner.ecf_id }

    let(:resource) { create(:declaration, lead_provider: current_lead_provider) }
    let(:resource_id) { resource.ecf_id }
    let(:service) { Declarations::ChangeDeliveryPartner }
    let(:action) { :change_delivery_partner }

    let(:service_args) { { declaration: resource, delivery_partner_id:, secondary_delivery_partner_id: } }

    let(:attributes) do
      {
        delivery_partner_id:,
        secondary_delivery_partner_id:,
      }
    end

    def path(id = nil)
      change_delivery_partner_api_v3_declaration_path(ecf_id: id)
    end

    it_behaves_like "an API update endpoint"
    it_behaves_like "changing a declaration by another lead provider"

    context "when a parameter is missing" do
      let(:attributes) do
        {
          secondary_delivery_partner_id:,
        }
      end

      let(:params) { { data: {} } }

      before do
        api_put(path(resource_id), params:)
      end

      it "has proper response status" do
        expect(response.status).to eq(400)
      end
    end
  end

  describe "POST /api/v3/participant-declarations" do
    let(:path) { api_v3_declarations_path }

    let(:service) { Declarations::Create }
    let(:action) { :create_declaration }
    let(:lead_provider) { current_lead_provider }
    let(:cohort) { create(:cohort, :current) }
    let(:course_group) { CourseGroup.find_by(name: "leadership") || create(:course_group, name: "leadership") }
    let(:course) { create(:course, :senior_leadership, course_group:) }
    let!(:schedule) { create(:schedule, :npq_leadership_autumn, course_group:, cohort:) }
    let(:application) { create(:application, :accepted, cohort:, course:, lead_provider:) }
    let(:participant) { application.user }
    let!(:participant_id) { participant.ecf_id }
    let(:declaration_type) { "completed" }
    let(:declaration_date) { (schedule.applies_from + 1.day).rfc3339 }
    let(:course_identifier) { course.identifier }
    let(:has_passed) { true }
    let(:delivery_partner_id) { create(:delivery_partner, lead_providers: { cohort => lead_provider }).ecf_id }
    let(:secondary_delivery_partner_id) { create(:delivery_partner, lead_providers: { cohort => lead_provider }).ecf_id }
    let(:attributes) do
      {
        participant_id:,
        declaration_type:,
        declaration_date:,
        course_identifier:,
        has_passed:,
        delivery_partner_id:,
        secondary_delivery_partner_id:,
      }
    end
    let(:service_args) { { lead_provider: }.merge!(attributes) }
    let(:resource) { build(:declaration, lead_provider:) }
    let(:resource_id) { resource.ecf_id }
    let(:resource_name) { :declaration }

    it_behaves_like "an API create endpoint"
  end
end
