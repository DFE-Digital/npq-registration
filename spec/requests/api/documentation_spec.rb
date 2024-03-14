require "rails_helper"

RSpec.describe "API documentation", type: :request do
  let(:api_enabled) { true }

  before { allow(Rails.application.config).to receive(:npq_separation) { { api_enabled: } } }

  describe "GET /api/docs/:version" do
    subject(:perform_request) do
      get "/api/docs/#{version}"
      response
    end

    let(:version) { :v3 }

    it { is_expected.to have_http_status(:ok) }

    context "when the version does not exist" do
      let(:version) { :v0 }

      it { expect { perform_request }.to raise_error(ActionController::RoutingError, "Not found") }
    end

    context "when api_enabled is false" do
      let(:api_enabled) { false }

      it { expect { perform_request }.to raise_error(ActionController::RoutingError) }
    end
  end
end
