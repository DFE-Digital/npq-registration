require "rails_helper"

RSpec.describe "Pages" do
  %w[/cookies /accessibility-statement /choose-an-npq-and-provider].each do |path|
    describe "GET #{path}" do
      it "renders the page" do
        get path
        expect(response).to have_http_status(:ok)
      end

      it "renders the page when any format is accepted" do
        get path, headers: { "Accept" => "*/*" }
        expect(response).to have_http_status(:ok)
      end

      it "returns a 406 for other formats" do
        get "#{path}.json"
        expect(response).to have_http_status(:not_acceptable)
      end

      it "returns a 406 when JSON is asked for in the Accept header" do
        get path, headers: { "Accept" => "application/json" }
        expect(response).to have_http_status(:not_acceptable)
      end
    end
  end

  context "when a page is not included in the allow list" do
    before do
      Rails.application.routes.draw do
        get "/new-page", to: "pages#show", page: "new-page"
      end
    end

    after { Rails.application.reload_routes! }

    it "returns a 404" do
      get "/new-page"
      expect(response).to have_http_status(:not_found)
    end
  end
end
