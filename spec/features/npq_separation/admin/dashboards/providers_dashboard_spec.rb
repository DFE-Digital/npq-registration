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

  scenario "filtering providers dashboard by a single cohort updates application counts" do
    test_provider = create(:lead_provider, name: "Test Provider")
    current_cohort = Cohort.current
    previous_cohort = create(:cohort, start_year: current_cohort.start_year - 1)

    create_list(:application, 2, cohort: current_cohort, lead_provider: test_provider)

    create(:application, cohort: previous_cohort, lead_provider: test_provider)

    visit npq_separation_admin_dashboard_path("providers-dashboard")

    select previous_cohort.start_year.to_s, from: "Search by cohort"
    click_button "Search"

    expect(page).to have_content("Test Provider")
    expect(page).to have_content("1")
  end
end
