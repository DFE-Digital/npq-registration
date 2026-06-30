require "rails_helper"

RSpec.describe Admin::DashboardsController, type: :request do
  include Helpers::RequestAdminLogin

  describe("GET /admin/dashboards") do
    subject { get(admin_dashboards_path) && response }

    context "when signed in as a super admin" do
      before { sign_in_as_admin(super_admin: true) }

      it "returns a 200 OK response" do
        expect(subject).to(have_http_status(:ok))
      end
    end

    context "when signed in as an admin" do
      before { sign_in_as_admin }

      it "returns a 200 OK response" do
        expect(subject).to(have_http_status(:ok))
      end
    end

    context "when not signed in" do
      it "redirects to the sign in page" do
        expect(subject).to redirect_to(sign_in_path)
      end
    end
  end

  %w[providers-dashboard courses-dashboard].each do |dashboard_name|
    describe("GET /admin/dashboards/#{dashboard_name}") do
      subject { get(admin_dashboard_path(name: dashboard_name)) && response }

      context "when signed in as a super admin" do
        before { sign_in_as_admin(super_admin: true) }

        it "returns a 200 OK response" do
          expect(subject).to have_http_status(:ok)
        end
      end

      context "when signed in as an admin" do
        before { sign_in_as_admin }

        it "returns a 200 OK response" do
          expect(subject).to have_http_status(:ok)
        end
      end

      context "when not signed in" do
        it "redirects to the sign in page" do
          expect(subject).to redirect_to(sign_in_path)
        end
      end
    end
  end
end
