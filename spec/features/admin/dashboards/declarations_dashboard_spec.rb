require "rails_helper"

RSpec.feature "Viewing the declarations dashboard", type: :feature do
  include Helpers::AdminLogin

  let(:test_provider) { create(:lead_provider, name: "Test Provider") }
  let(:cohort) { create(:cohort, :current) }

  before do
    sign_in_as(create(:admin))
  end

  scenario "visiting the declarations dashboard from the navigation" do
    visit admin_dashboard_path("courses-dashboard")

    click_link "Declarations dashboard"

    expect(page).to have_css("h1", text: "Declarations dashboard")
    expect(page).to have_select("Provider")
    expect(page).to have_select("Cohort")
    expect(page).to have_button("Select")
  end

  scenario "no filter shows an inset and no table" do
    visit admin_declarations_dashboard_path

    expect(page).to have_content("Select a provider and cohort to view declaration data.")
    expect(page).not_to have_css("th", text: "Declaration type")
  end

  scenario "submitting choosing no values shows validation errors and no table" do
    visit admin_declarations_dashboard_path

    click_button "Select"

    expect(page).to have_css(".govuk-error-summary")
    expect(page).not_to have_css("th", text: "Declaration type")
  end

  scenario "choosing a provider and cohort shows the declaration summary table" do
    test_provider
    cohort

    visit admin_declarations_dashboard_path

    select "Test Provider", from: "Provider"
    select cohort.description, from: "Cohort"
    click_button "Select"

    expect(page).to have_css("h2", text: "Test Provider")
    expect(page).to have_content("Showing declaration data for the #{cohort.description} cohort.")

    expect(page).to have_css("th", text: "Declaration type")
    expect(page).to have_css("th", text: "Expected")
    expect(page).to have_css("th", text: "Received")
    expect(page).to have_css("th", text: "Remaining")

    expect(page).to have_css("th", text: "Started")
    expect(page).to have_css("th", text: "Retained-1")
    expect(page).to have_css("th", text: "Retained-2")
    expect(page).to have_css("th", text: "Completed")
    expect(page).to have_css("th", text: "Total declarations")

    expect(page).to have_css("td.govuk-table__cell--numeric", text: "-", count: 15)
  end
end
