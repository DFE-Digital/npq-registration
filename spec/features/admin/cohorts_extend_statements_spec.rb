# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Cohort - add extra statements", :no_js, type: :feature do
  include Helpers::AdminLogin

  let :cohort do
    create(:cohort, :current) do
      create(:statement, for_date: 1.month.from_now, lead_provider: LeadProvider.first)
    end
  end

  before { allow(Cohorts::ExtendStatementsJob).to receive(:perform_later) }

  scenario "extending a cohort" do
    sign_in_as create(:super_admin)

    visit admin_cohort_path(cohort)
    click_on "Add extra statements"

    expect(page).to have_content "Extend end of Cohort"
    click_on "Back"

    expect(page).to have_current_path admin_cohort_path(cohort)
    click_on "Add extra statements"

    expect(page).to have_content "Extend end of Cohort"
    click_on "Cancel"

    expect(page).to have_current_path admin_cohort_path(cohort)
    click_on "Add extra statements"

    expect(page).to have_content "Extend end of Cohort"
    click_on "Continue"

    expect(page).to have_content "Extend end of Cohort"
    expect(page).to have_content "There is a problem"
    expect(Cohorts::ExtendStatementsJob).not_to have_received(:perform_later)

    fill_in "Month", with: "20"
    fill_in "Year", with: 5.years.from_now.year
    click_on "Continue"

    expect(page).to have_content "Extend end of Cohort"
    expect(page).to have_content "There is a problem"
    expect(Cohorts::ExtendStatementsJob).not_to have_received(:perform_later)

    fill_in "Month", with: "12"
    fill_in "Year", with: 5.years.from_now.year
    click_on "Continue"

    expect(page).to have_current_path admin_cohort_path(cohort)
    expect(Cohorts::ExtendStatementsJob).to have_received(:perform_later)
    expect(page).to have_content "Cohort is being extended"
  end

  scenario "when attempting to change output as a regular admin" do
    sign_in_as create(:admin)

    visit admin_cohort_path(cohort)
    expect(page).not_to have_link("Add extra statements")

    visit admin_cohort_extend_statements_path(cohort)
    expect(page).to have_current_path sign_in_path
  end

  scenario "when not signed in" do
    visit admin_cohort_extend_statements_path(cohort)
    expect(page).to have_current_path sign_in_path
  end
end
