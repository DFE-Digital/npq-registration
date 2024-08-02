require "rails_helper"

RSpec.describe "Participant endpoints", type: :request do
  let(:current_lead_provider) { create(:lead_provider) }
  let(:query) { Participants::Query }
  let(:serializer) { API::ParticipantSerializer }
  let(:serializer_version) { :v2 }
  let(:serializer_lead_provider) { current_lead_provider }

  describe "GET /api/v2/participants/npq" do
    let(:path) { api_v2_participants_path }
    let(:resource_id_key) { :ecf_id }

    def create_resource(**attrs)
      create(:user, :with_application, **attrs)
    end

    it_behaves_like "an API index endpoint"
    it_behaves_like "an API index endpoint with pagination"
    it_behaves_like "an API index endpoint with filter by updated_since"
  end

  describe "GET /api/v2/participants/npq/:id" do
    let(:resource) { create(:user, :with_application, lead_provider: current_lead_provider) }
    let(:resource_id) { resource.ecf_id }

    def path(id = nil)
      api_v2_participant_path(id)
    end

    it_behaves_like "an API show endpoint"
  end

  describe "PUT /api/v2/participants/:ecf_id/resume" do
    let(:application) { create(:application, :accepted, lead_provider: current_lead_provider) }
    let(:resource) { application.user }
    let(:resource_id) { resource.ecf_id }
    let(:service) { Participants::Resume }
    let(:action) { :resume }
    let(:attributes) { { course_identifier: "course", lead_provider: current_lead_provider } }
    let(:service_args) { { participant_id: resource_id }.merge!(attributes) }
    let(:service_methods) { { participant: resource } }

    def path(id = nil)
      resume_api_v2_participant_path(ecf_id: id)
    end

    it_behaves_like "an API update endpoint"
  end

  describe "PUT /api/v2/participants/:ecf_id/defer" do
    let(:application) { create(:application, :accepted, lead_provider: current_lead_provider) }
    let(:resource) { application.user }
    let(:resource_id) { resource.ecf_id }
    let(:service) { Participants::Defer }
    let(:action) { :defer }
    let(:attributes) { { course_identifier: "course", reason: "reason", lead_provider: current_lead_provider } }
    let(:service_args) { { participant_id: resource_id }.merge!(attributes) }
    let(:service_methods) { { participant: resource } }

    def path(id = nil)
      defer_api_v2_participant_path(ecf_id: id)
    end

    it_behaves_like "an API update endpoint"
  end

  describe "PUT /api/v2/participants/:ecf_id/withdraw" do
    let(:application) { create(:application, :accepted, lead_provider: current_lead_provider) }
    let(:resource) { application.user }
    let(:resource_id) { resource.ecf_id }
    let(:service) { Participants::Withdraw }
    let(:action) { :withdraw }
    let(:attributes) { { course_identifier: "course", reason: "reason", lead_provider: current_lead_provider } }
    let(:service_args) { { participant_id: resource_id }.merge!(attributes) }
    let(:service_methods) { { participant: resource } }

    def path(id = nil)
      withdraw_api_v2_participant_path(ecf_id: id)
    end

    it_behaves_like "an API update endpoint"
  end

  describe "PUT /api/v2/participants/:ecf_id/change-schedule" do
    let(:application) { create(:application, :with_declaration, lead_provider: current_lead_provider) }
    let(:schedule_identifier) { application.schedule.identifier }
    let(:course_identifier) { application.course.identifier }
    let(:resource) { application.user }
    let(:resource_id) { resource.ecf_id }
    let(:service) { Participants::ChangeSchedule }
    let(:action) { :change_schedule }
    let(:attributes) { { schedule_identifier:, course_identifier:, lead_provider: current_lead_provider } }
    let(:service_args) { { participant_id: resource_id }.merge!(attributes) }
    let(:service_methods) { { participant: resource } }

    def path(id = nil)
      change_schedule_api_v2_participant_path(id)
    end

    it_behaves_like "an API update endpoint"
  end
end
