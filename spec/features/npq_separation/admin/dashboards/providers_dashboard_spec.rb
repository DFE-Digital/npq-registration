require "rails_helper"

RSpec.feature "Viewing the providers dashboard", type: :feature do
  include Helpers::AdminLogin

  before do
    create :cohort, :current
    sign_in_as(create(:admin))
  end

  scenario "viewing the providers dashboard table" do
    visit(npq_separation_admin_dashboard_path("providers-dashboard"))

    expect(page).to have_css("h1", text: "Providers dashboard")
    expect(page).to have_css("th", text: "Provider")
    expect(page).to have_css("th", text: "Applications")
  end

  scenario "filtering providers dashboard by a single cohort" do
    test_provider = create(:lead_provider, name: "Filtered Provider")
    create(:application, cohort: Cohort.current, lead_provider: test_provider)

    visit npq_separation_admin_dashboard_path("providers-dashboard")

    select Cohort.current.start_year.to_s, from: "Search by cohort"
    click_button "Search"

    expect(page).to have_content("Filtered Provider")
  end
end
