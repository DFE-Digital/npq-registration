require "rails_helper"

RSpec.describe "Participant outcome endpoints", type: :request do
  let(:current_lead_provider) { create(:lead_provider) }
  let(:query) { ParticipantOutcomes::Query }
  let(:serializer) { API::ParticipantOutcomeSerializer }
  let(:serializer_version) { :v1 }

  def create_resource(**attrs)
    if attrs[:lead_provider]
      attrs[:declaration] = create(:declaration, lead_provider: attrs[:lead_provider])
      attrs.delete(:lead_provider)
    end

    create(:participant_outcome, **attrs)
  end

  describe "GET /api/v1/participants/npq/outcomes" do
    let(:path) { api_v1_participant_outcomes_path }
    let(:resource_id_key) { :ecf_id }

    it_behaves_like "an API index endpoint"
    it_behaves_like "an API index endpoint with pagination"
    it_behaves_like "an API index endpoint with filter by created_since"
  end
end
