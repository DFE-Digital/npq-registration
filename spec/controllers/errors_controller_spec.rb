require "rails_helper"

RSpec.describe ErrorsController, type: :controller do
  describe "GET #not_found" do
    it "returns not found" do
      get :not_found
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET #internal_server_error" do
    it "returns internal_server_error" do
      get :internal_server_error
      expect(response).to have_http_status(:internal_server_error)
    end
  end

  describe "GET #unprocessable_content" do
    it "returns unprocessable_content" do
      get :unprocessable_content
      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
