require "rails_helper"

RSpec.describe NpqSeparation::Admin::DashboardsHelper, type: :helper do
  describe "#render_dashboard_partial" do
    it "raises ActionController::RoutingError when given an invalid dashboard name" do
      expect {
        helper.render_dashboard_partial("invalid-dashboard")
      }.to raise_error(ActionController::RoutingError, "Not Found")
    end
  end
end
