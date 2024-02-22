require "rails_helper"

RSpec.describe NpqSeparation::AdminController, type: :request do
  include Helpers::NPQSeparationAdminLogin

  context "when admin is not logged in" do
    it "redirects to the sign in page" do
      expect(get(npq_separation_admin_path)).to redirect_to(sign_in_path)
    end
  end

  context "when admin is logged in" do
    it "shows the admin landing page" do
      sign_in_as_admin

      expect(get(npq_separation_admin_path)).to eq(200)
    end
  end
end
