require "rails_helper"

RSpec.describe "Participants outcome endpoints", type: :request do
  let(:current_lead_provider) { create(:lead_provider) }
  let(:query) { ParticipantOutcomes::Query }
  let(:serializer) { API::ParticipantOutcomeSerializer }
  let(:serializer_version) { :v2 }
  let(:application) { create(:application, :accepted, lead_provider: current_lead_provider) }
  let(:user) { application.user }

  def create_resource(created_since: nil, updated_since: nil, **attrs)
    if attrs[:lead_provider]
      attrs[:declaration] = create_declaration(application:, lead_provider: attrs[:lead_provider])
      attrs.delete(:lead_provider)
    end

    outcome = create(:participant_outcome, **attrs)
    outcome.update_attribute(:updated_at, updated_since) if updated_since # rubocop:disable Rails/SkipsModelValidations
    outcome.update_attribute(:created_at, created_since) if created_since # rubocop:disable Rails/SkipsModelValidations

    outcome
  end

  def create_resource_with_different_parent(**attrs)
    create_resource(**attrs).tap do |outcome|
      declaration_date = application.schedule.applies_from + 1.day
      travel_to(declaration_date) do
        outcome.declaration.update!(
          application: create(:application, :accepted, user: create(:user, full_name: "Other User")),
        )
      end
    end
  end

  describe "GET /api/v2/participants/npq/:participant_id/outcomes" do
    let(:path) { api_v2_participants_outcomes_path(user.ecf_id) }
    let(:resource_id_key) { :ecf_id }

    it_behaves_like "an API index endpoint"
    it_behaves_like "an API index endpoint on a parent resource", "participant", "outcome"
    it_behaves_like "an API index endpoint with pagination"
  end

  describe "POST /api/v2/participants/npq/:participant_id/outcomes" do
    let(:path) { api_v2_participants_outcomes_path(user.ecf_id) }
    let(:attributes) do
      {
        state: ParticipantOutcomes::Create::STATES.sample,
        completion_date: 1.day.ago.strftime("%Y-%m-%d"),
        course_identifier: ParticipantOutcomes::Create::PERMITTED_COURSES.sample,
      }
    end
    let(:service) { ParticipantOutcomes::Create }
    let(:action) { :create_outcome }
    let(:service_args) { { lead_provider: current_lead_provider, participant_id: user.ecf_id }.merge!(attributes) }
    let(:service_methods) { { participant: user } }
    let(:resource) { build(:participant_outcome) }
    let(:resource_id) { resource.ecf_id }
    let(:resource_name) { :created_outcome }

    it_behaves_like "an API create endpoint"
  end
end
