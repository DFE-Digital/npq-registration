# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Omniauth passthru", type: :request do
  describe "GET /users/auth/tra_openid_connect" do
    it "returns a 404 status" do
      get "/users/auth/tra_openid_connect"

      expect(response).to have_http_status(:not_found)
      expect(response.body).to include("Not found. Authentication passthru.")
    end
  end
end
