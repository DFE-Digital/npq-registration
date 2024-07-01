require "rails_helper"

RSpec.describe "Participants outcome endpoints", type: :request do
  let(:current_lead_provider) { create(:lead_provider) }
  let(:query) { ParticipantOutcomes::Query }
  let(:serializer) { API::ParticipantOutcomeSerializer }
  let(:serializer_version) { :v2 }
  let(:application) { create(:application, :accepted, lead_provider: current_lead_provider) }
  let(:user) { application.user }

  def create_resource(**attrs)
    if attrs[:lead_provider]
      attrs[:declaration] = create(:declaration, application:, lead_provider: attrs[:lead_provider])
      attrs.delete(:lead_provider)
    end

    create(:participant_outcome, **attrs)
  end

  def create_resource_with_different_parent(**attrs)
    create_resource(**attrs).tap do |outcome|
      outcome.declaration.update!(
        application: create(:application, :accepted, user: create(:user, full_name: "Other User")),
      )
    end
  end

  describe "GET /api/v2/participants/npq/:participant_id/outcomes" do
    let(:path) { api_v2_participants_outcomes_path(user.ecf_id) }
    let(:resource_id_key) { :ecf_id }

    it_behaves_like "an API index endpoint"
    it_behaves_like "an API index endpoint on a parent resource", "participant", "outcome"
    it_behaves_like "an API index endpoint with pagination"
  end

  describe("create") do
    before { api_post(api_v2_participants_outcomes_path(123)) }

    specify { expect(response).to(be_method_not_allowed) }
  end
end
