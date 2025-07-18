require "rails_helper"

RSpec.describe "Error responses", type: :request do
  include_context "when errors are rendered"

  describe "not found" do
    it "returns a JSON error response" do
      api_get "/api/v3/thisdoesnotexist"
      expect(response).to have_http_status(:not_found)
      expect(response.body).to eq %({"error":"Resource not found"})
      expect(response.content_type).to match(/application\/json.*/)
    end

    context "when the request is for a CSV" do
      it "returns an plain text response" do
        api_get "/api/v2/thisdoesnotexist.csv"
        expect(response).to have_http_status(:not_found)
        expect(response.body).to be_empty
        expect(response.content_type).to match(/text\/plain.*/)
      end
    end
  end

  describe "internal server error" do
    before do
      allow(Applications::Query).to receive(:new).and_raise(StandardError)
    end

    it "returns a JSON error response" do
      api_get "/api/v3/npq-applications"
      expect(response).to have_http_status(:internal_server_error)
      expect(response.body).to eq %({"error":"Internal server error"})
      expect(response.content_type).to match(/application\/json.*/)
    end

    context "when the request is for a CSV", skip: Rails.configuration.x.disable_legacy_api do
      it "returns an plain text response" do
        api_get "/api/v2/npq-applications.csv"
        expect(response).to have_http_status(:internal_server_error)
        expect(response.body).to be_empty
        expect(response.content_type).to match(/text\/plain.*/)
      end
    end
  end

  describe "unprocessable entity" do
    before do
      allow(Applications::Query).to receive(:new).and_raise(ActiveRecord::RecordInvalid)
    end

    it "returns a JSON error response" do
      api_get "/api/v3/npq-applications"
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to eq %({"error":"Unprocessable entity"})
      expect(response.content_type).to match(/application\/json.*/)
    end

    context "when the request is for a CSV", skip: Rails.configuration.x.disable_legacy_api do
      it "returns an plain text response" do
        api_get "/api/v2/npq-applications.csv"
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to be_empty
        expect(response.content_type).to match(/text\/plain.*/)
      end
    end
  end
end
