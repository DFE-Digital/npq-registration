require "rails_helper"

RSpec.feature "Viewing summary dashboard", type: :feature do
  include Helpers::AdminLogin

  before do
    create :cohort, :current
    sign_in_as(create(:admin))
  end

  scenario "viewing the summary tables" do
    visit(npq_separation_admin_dashboards_providers_dashboard_path)

    expect(page).to have_css("h1", text: "Providers dashboard")
    expect(page).to have_css("th", text: "Provider")
    expect(page).to have_css("th", text: "Applications")
  end
end
