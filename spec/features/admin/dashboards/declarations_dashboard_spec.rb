require "rails_helper"

RSpec.feature "Viewing the declarations dashboard", type: :feature do
  include Helpers::AdminLogin

  let(:test_provider) { create(:lead_provider, name: "Test Provider") }
  let(:cohort) { create(:cohort, :current) }
  let(:schedule) { create(:schedule, :npq_leadership_autumn, cohort:) }
  let(:statement) { create(:statement, lead_provider: test_provider, cohort:, for_date: 2.months.ago) }

  before do
    sign_in_as(create(:admin))
  end

  def add_started_declarations
    milestone = create(:milestone, schedule:, declaration_type: "started")
    create(:milestone_statement, milestone:, statement:)

    applications = create_list(:application, 3, :accepted, lead_provider: test_provider, cohort:, schedule:)
    create(:declaration, :eligible, declaration_type: "started", application: applications.first, lead_provider: test_provider, cohort:, statement:)
  end

  def row_values(label)
    find("th", text: label, exact_text: true).ancestor("tr").all("td").map(&:text)
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
    within(".govuk-error-summary") do
      expect(page).to have_link("Choose a provider")
      expect(page).to have_link("Choose a cohort")
    end

    expect(page).to have_css(".govuk-error-message", text: "Choose a provider")
    expect(page).to have_css(".govuk-error-message", text: "Choose a cohort")

    expect(page).to have_content("Choose a provider and cohort")
    expect(page).not_to have_css("th", text: "Declaration type")
  end

  scenario "choosing a provider and cohort shows the declaration summary table" do
    add_started_declarations

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

    expect(row_values("Started")).to eq(%w[3 1 2])
    expect(row_values("Retained-1")).to eq(%w[0 0 0])
    expect(row_values("Retained-2")).to eq(%w[0 0 0])
    expect(row_values("Completed")).to eq(%w[0 0 0])
    expect(row_values("Total declarations")).to eq(%w[3 1 2])
  end

  scenario "the chosen provider and cohort stay selected" do
    test_provider
    cohort

    visit admin_declarations_dashboard_path

    select "Test Provider", from: "Provider"
    select cohort.description, from: "Cohort"
    click_button "Select"

    expect(page).to have_select("Provider", selected: "Test Provider")
    expect(page).to have_select("Cohort", selected: cohort.description)
  end

  scenario "changing the provider refreshes the table" do
    add_started_declarations
    other_provider = create(:lead_provider, name: "Other Provider")

    visit admin_declarations_dashboard_path

    select "Test Provider", from: "Provider"
    select cohort.description, from: "Cohort"
    click_button "Select"

    expect(row_values("Started")).to eq(%w[3 1 2])

    select other_provider.name, from: "Provider"
    click_button "Select"

    expect(page).to have_css("h2", text: "Other Provider")
    expect(row_values("Started")).to eq(%w[0 0 0])
  end
end
