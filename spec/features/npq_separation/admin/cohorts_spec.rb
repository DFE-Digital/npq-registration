require "rails_helper"

RSpec.feature "Managing cohorts", :ecf_api_disabled, type: :feature do
  include Helpers::AdminLogin

  let(:cohort) { Cohort.find_by start_year: 2026 }

  before do
    (2026..2028).each { create :cohort, start_year: _1 }

    sign_in_as(create(:admin))
  end

  scenario "viewing the list of cohorts" do
    visit(npq_separation_admin_cohorts_path)

    expect(Cohort.count).to eq(3)

    expect(page).to have_table(rows: [
      ["2028/29", "3 April 2028", "No"],
      ["2027/28", "3 April 2027", "No"],
      ["2026/27", "3 April 2026", "No"],
    ])
  end

  scenario "viewing cohort details" do
    visit(npq_separation_admin_cohorts_path)
    click_on "2026/27"

    expect(page).to have_css("h1", text: "Cohort 2026/27")

    within(".govuk-summary-list") do |summary_list|
      expect(summary_list).to have_summary_item("Start year", "2026")
      expect(summary_list).to have_summary_item("Registration start date", "3 April 2026")
      expect(summary_list).to have_summary_item("Funding cap", "No")
    end
  end

  scenario "creating a new cohort" do
    visit(npq_separation_admin_cohorts_path)
    click_on "New cohort"

    fill_in "Start year", with: "2029"
    check "Funding cap", visible: :all
    fill_in "Day", with: "2"
    fill_in "Month", with: "3"
    fill_in "Year", with: "2029"

    # TODO: rename this button
    expect { click_on "Continue" }.to change(Cohort, :count).by(1)

    cohort = Cohort.order(created_at: :desc).first
    expect(cohort.start_year).to be(2029)
    expect(cohort.funding_cap).to be(true)
    expect(cohort.registration_start_date).to eq(Date.new(2029, 3, 2))
  end

  scenario "editing a cohort" do
    cohort.update! funding_cap: false

    visit(npq_separation_admin_cohorts_path)
    click_on "2026/27"
    click_on "Edit cohort details"

    fill_in "Start year", with: "2025"
    check "Funding cap", visible: :all
    fill_in "Day", with: "6"
    fill_in "Month", with: "5"
    fill_in "Year", with: "2025"

    # TODO: rename this button
    expect { click_on "Continue" }.not_to(change(Cohort, :count))
    expect(page).to have_text("Cohort updated")

    cohort.reload
    expect(cohort.start_year).to be(2025)
    expect(cohort.funding_cap).to be(true)
    expect(cohort.registration_start_date.to_date).to eq(Date.new(2025, 5, 6))
  end

  scenario "destroying a cohort" do
    pending "Not yet implemented"
    fail
  end
end
