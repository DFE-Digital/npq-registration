require "rails_helper"

RSpec.describe "Participant outcome endpoints", type: :request do
  let(:current_lead_provider) { create(:lead_provider) }
  let(:query) { ParticipantOutcomes::Query }
  let(:serializer) { API::ParticipantOutcomeSerializer }
  let(:serializer_version) { :v3 }

  def create_resource(created_since: nil, updated_since: nil, **attrs)
    if attrs[:lead_provider]
      attrs[:declaration] = create_declaration(lead_provider: attrs[:lead_provider])
      attrs.delete(:lead_provider)
    end

    outcome = create(:participant_outcome, **attrs)
    outcome.update_attribute(:updated_at, updated_since) if updated_since # rubocop:disable Rails/SkipsModelValidations
    outcome.update_attribute(:created_at, created_since) if created_since # rubocop:disable Rails/SkipsModelValidations

    outcome
  end

  describe "GET /api/v3/participants/npq/outcomes" do
    let(:path) { api_v3_participant_outcomes_path }
    let(:resource_id_key) { :ecf_id }

    it_behaves_like "an API index endpoint"
    it_behaves_like "an API index endpoint with pagination"
    it_behaves_like "an API index endpoint with filter by created_since"
  end
end
