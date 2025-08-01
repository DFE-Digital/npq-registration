require "rails_helper"

RSpec.feature "Viewing the dashboard introduction", type: :feature do
  include Helpers::AdminLogin

  before do
    create :cohort, :current
    sign_in_as(create(:admin))
  end

  scenario "Viewing the dashboard introduction" do
    visit(npq_separation_admin_dashboards_path)

    expect(page).to have_css("h1", text: "Dashboards")
    expect(page).to have_link("Courses dashboard")
    expect(page).to have_link("Providers dashboard")
  end
end
