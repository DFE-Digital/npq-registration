# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Registration redirect" do
  describe "GET /registration" do
    before { get "/registration" }

    it { expect(response).to redirect_to("/") }
    it { expect(response).to have_http_status(:moved_permanently) }
  end

  describe "GET /registration/:step still works" do
    before { get "/registration/start" }

    it { expect(response).to have_http_status(:success) }
  end
end
