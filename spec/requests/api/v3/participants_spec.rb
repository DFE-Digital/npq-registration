require "rails_helper"

RSpec.describe "Participant endpoints", type: :request do
  let(:current_lead_provider) { create(:lead_provider) }
  let(:query) { Participants::Query }
  let(:serializer) { API::ParticipantSerializer }
  let(:serializer_version) { :v3 }
  let(:serializer_lead_provider) { current_lead_provider }

  describe "GET /api/v3/participants/npq" do
    let(:path) { api_v3_participants_path }
    let(:resource_id_key) { :ecf_id }

    def create_resource(created_since: nil, updated_since: nil, **attrs)
      user = create(:user, :with_application, **attrs)
      user.update_attribute(:updated_at, updated_since) if updated_since # rubocop:disable Rails/SkipsModelValidations
      user.applications.first.update_attribute(:updated_at, updated_since) if updated_since # rubocop:disable Rails/SkipsModelValidations
      user.update_attribute(:created_at, created_since) if created_since # rubocop:disable Rails/SkipsModelValidations
      user.applications.first.update_attribute(:created_at, created_since) if created_since # rubocop:disable Rails/SkipsModelValidations

      user
    end

    it_behaves_like "an API index endpoint"
    it_behaves_like "an API index endpoint with pagination"
    it_behaves_like "an API index endpoint with filter by updated_since"
    it_behaves_like "an API index endpoint with filter by training_status"
    it_behaves_like "an API index endpoint with filter by from_participant_id"
    it_behaves_like "an API index endpoint with sorting"
  end

  describe "GET /api/v3/participants/npq/:id" do
    let(:resource) { create(:user, :with_application, lead_provider: current_lead_provider) }
    let(:resource_id) { resource.ecf_id }

    def path(id = nil)
      api_v3_participant_path(id)
    end

    it_behaves_like "an API show endpoint"
  end

  describe "PUT /api/v3/participants/:ecf_id/resume" do
    let(:application) { create(:application, :accepted, lead_provider: current_lead_provider) }
    let(:resource) { application.user }
    let(:resource_id) { resource.ecf_id }
    let(:service) { Participants::Resume }
    let(:action) { :resume }
    let(:attributes) { { course_identifier: "course", lead_provider: current_lead_provider } }
    let(:service_args) { { participant_id: resource_id }.merge!(attributes) }
    let(:service_methods) { { participant: resource } }

    def path(id = nil)
      resume_api_v3_participant_path(ecf_id: id)
    end

    it_behaves_like "an API update endpoint"
  end

  describe "PUT /api/v3/participants/:ecf_id/defer" do
    let(:application) { create(:application, :accepted, lead_provider: current_lead_provider) }
    let(:resource) { application.user }
    let(:resource_id) { resource.ecf_id }
    let(:service) { Participants::Defer }
    let(:action) { :defer }
    let(:attributes) { { course_identifier: "course", reason: "reason", lead_provider: current_lead_provider } }
    let(:service_args) { { participant_id: resource_id }.merge!(attributes) }
    let(:service_methods) { { participant: resource } }

    def path(id = nil)
      defer_api_v3_participant_path(ecf_id: id)
    end

    it_behaves_like "an API update endpoint"
  end

  describe "PUT /api/v3/participants/:ecf_id/withdraw" do
    let(:application) { create(:application, :accepted, lead_provider: current_lead_provider) }
    let(:resource) { application.user }
    let(:resource_id) { resource.ecf_id }
    let(:service) { Participants::Withdraw }
    let(:action) { :withdraw }
    let(:attributes) { { course_identifier: "course", reason: "reason", lead_provider: current_lead_provider } }
    let(:service_args) { { participant_id: resource_id }.merge!(attributes) }
    let(:service_methods) { { participant: resource } }

    def path(id = nil)
      withdraw_api_v3_participant_path(ecf_id: id)
    end

    it_behaves_like "an API update endpoint"
  end

  describe "PUT /api/v3/participants/:ecf_id/change-schedule" do
    let(:application) { create_application_with_declaration(lead_provider: current_lead_provider) }
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
      change_schedule_api_v3_participant_path(id)
    end

    it_behaves_like "an API update endpoint"
  end
end
