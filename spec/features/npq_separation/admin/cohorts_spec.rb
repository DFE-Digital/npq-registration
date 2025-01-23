require "rails_helper"

RSpec.feature "Managing cohorts", :ecf_api_disabled, type: :feature do
  include Helpers::AdminLogin

  let(:admin)  { create :admin }
  let(:cohort) { Cohort.find_by start_year: 2026 }

  let(:new_button_text)    { "New cohort" }
  let(:edit_button_text)   { "Edit cohort details" }
  let(:delete_button_text) { "Delete cohort" }

  before do
    (2026..2028).each { create :cohort, start_year: _1 }

    sign_in_as admin
  end

  scenario "listing cohorts" do
    visit_index

    expect(Cohort.count).to eq(3)

    expect(page).to have_table(rows: [
      ["2028/29", "3 April 2028", "No"],
      ["2027/28", "3 April 2027", "No"],
      ["2026/27", "3 April 2026", "No"],
    ])
  end

  scenario "viewing details" do
    navigate_to_cohort

    expect(page).to have_css("h1", text: "Cohort 2026/27")

    within(".govuk-summary-list") do |summary_list|
      expect(summary_list).to have_summary_item("Start year", "2026")
      expect(summary_list).to have_summary_item("Registration start date", "3 April 2026")
      expect(summary_list).to have_summary_item("Funding cap", "No")
    end
  end

  context "when logged in as a super admin" do
    before do
      admin.update! super_admin: true
    end

    scenario "creation" do
      visit_index
      click_on new_button_text

      fill_in "Start year", with: "2029"
      check "Funding cap", visible: :all
      fill_in "Day", with: "2"
      fill_in "Month", with: "3"
      fill_in "Year", with: "2029"

      expect { click_on "Create cohort" }.to change(Cohort, :count).by(1)

      cohort = Cohort.order(created_at: :desc).first
      expect(cohort.start_year).to be(2029)
      expect(cohort.funding_cap).to be(true)
      expect(cohort.registration_start_date).to eq(Date.new(2029, 3, 2))
    end

    scenario "editing" do
      cohort.update! funding_cap: false

      navigate_to_cohort
      click_on edit_button_text

      fill_in "Start year", with: "2025"
      check "Funding cap", visible: :all
      fill_in "Day", with: "6"
      fill_in "Month", with: "5"
      fill_in "Year", with: "2025"

      expect { click_on "Update cohort" }.not_to(change(Cohort, :count))
      expect(page).to have_text("Cohort updated")

      cohort.reload
      expect(cohort.start_year).to be(2025)
      expect(cohort.funding_cap).to be(true)
      expect(cohort.registration_start_date.to_date).to eq(Date.new(2025, 5, 6))
    end

    scenario "deletion" do
      navigate_to_cohort
      click_on delete_button_text

      expect { click_on "Confirm" }.to change(Cohort, :count).by(-1)
    end
  end

  context "when logged in as a normal admin" do
    scenario "cannot create" do
      visit_index
      expect(page).not_to have_link(new_button_text)
    end

    scenario "cannot edit" do
      navigate_to_cohort
      expect(page).not_to have_link(edit_button_text)
    end

    scenario "cannot delete" do
      navigate_to_cohort
      expect(page).not_to have_link(delete_button_text)
    end
  end

private

  def visit_index
    visit npq_separation_admin_cohorts_path
  end

  def navigate_to_cohort
    visit_index
    click_on "2026/27"
  end
end
