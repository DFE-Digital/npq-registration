# frozen_string_literal: true

require "rails_helper"

RSpec.shared_examples "a declaration void action" do
  context "when voiding declaration with passed outcome" do
    let(:resource) { create(:participant_outcome, :passed, lead_provider: current_lead_provider).declaration }
    let(:params) { defined?(attributes) ? { data: { attributes: } } : nil }

    it "returns the updated attributes" do
      api_get(get_path(resource_id))
      expect(response.status).to eq 200
      expect(parsed_response["data"]["attributes"]["has_passed"]).to be(true)

      api_put(path(resource_id), params:)
      expect(response.status).to eq 200
      expect(parsed_response["data"]["id"]).to eq(resource_id)
      expect(parsed_response["data"]["attributes"]["has_passed"]).to be_nil
    end
  end
end
