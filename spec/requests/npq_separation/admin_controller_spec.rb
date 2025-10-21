require "rails_helper"

RSpec.describe NpqSeparation::AdminController, type: :request do
  include Helpers::NPQSeparationAdminLogin

  subject(:admin_response) { get(npq_separation_admin_path) && response }

  context "when admin is not logged in" do
    it "redirects to the sign in page" do
      expect(admin_response).to redirect_to(sign_in_path)
    end
  end

  context "when admin is logged in" do
    before do
      travel_to Time.zone.now.utc.beginning_of_day + 5.minutes do
        create :cohort, :current

        sign_in_as_admin
      end
    end

    it "shows the admin landing page" do
      travel_to Time.zone.now.utc.end_of_day - 5.minutes do
        expect(admin_response).to have_http_status :success
      end
    end

    it "includes no-store cache headers" do
      expect(admin_response.headers).to include "Cache-Control" => "no-store"
    end
  end

  context "when admin session is from yesterday" do
    before do
      travel_to Time.zone.now.utc.beginning_of_day - 1.minute do
        create :cohort, :current

        sign_in_as_admin
      end
    end

    it "redirects to the sign in page" do
      travel_to Time.zone.now.utc.beginning_of_day + 1.minute do
        expect(admin_response).to redirect_to(sign_in_path)
      end
    end
  end
end
