require "rails_helper"

RSpec.feature "Applications in review", type: :feature do
  include Helpers::AdminLogin

  let(:cohort_21) { create(:cohort, start_year: 2021) }
  let(:cohort_22) { create(:cohort, start_year: 2022) }

  let!(:normal_application)                         { create(:application) }
  let!(:application_for_hospital_school)            { create(:application, employment_type: "hospital_school", employer_name: Faker::Company.name, cohort: cohort_21, referred_by_return_to_teaching_adviser: "yes") }
  let!(:application_for_la_supply_teacher)          { create(:application, employment_type: "local_authority_supply_teacher", cohort: cohort_22, referred_by_return_to_teaching_adviser: "no") }
  let!(:application_for_la_virtual_school)          { create(:application, employment_type: "local_authority_virtual_school") }
  let!(:application_for_young_offender_institution) { create(:application, employment_type: "young_offender_institution") }
  let!(:application_for_other)                      { create(:application, employment_type: "other") }
  let!(:application_for_rtta_yes)                   { create(:application, referred_by_return_to_teaching_adviser: "yes") }
  let!(:application_for_rtta_no)                    { create(:application, referred_by_return_to_teaching_adviser: "no") }

  before do
    sign_in_as create(:admin)
    visit npq_separation_admin_applications_path
    click_on "In review"
  end

  scenario "listing" do
    rows = [
      application_for_hospital_school,
      application_for_la_supply_teacher,
      application_for_la_virtual_school,
      application_for_young_offender_institution,
      application_for_other,
      application_for_rtta_yes,
    ].map do |application|
      [
        [application.user.full_name, application.employment_type.try(:humanize), application.employer_name].compact.join,
        application.eligible_for_funding ? "Yes" : "No",
        application.lead_provider_approval_status.humanize,
        application.notes.to_s,
        application.created_at.to_fs(:govuk_short),
      ]
    end

    expect(page).to have_table(rows:)
    expect(page).not_to have_text normal_application.user.full_name
    expect(page).not_to have_text application_for_rtta_no.user.full_name
  end

  scenario "searching with participant ID" do
    fill_in("Enter the participant ID", with: application_for_hospital_school.user.ecf_id)
    click_on "Search"

    expect(page).to have_text(application_for_hospital_school.user.full_name)
    expect(page).not_to have_text(application_for_la_supply_teacher.user.full_name)
  end

  scenario "searching with participant name" do
    fill_in("Enter the participant ID", with: application_for_hospital_school.user.full_name)
    click_on "Search"

    expect(page).to have_text(application_for_hospital_school.user.full_name)
    expect(page).not_to have_text(application_for_la_supply_teacher.user.full_name)
  end

  scenario "searching with participant email" do
    fill_in("Enter the participant ID", with: application_for_hospital_school.user.email)
    click_on "Search"

    expect(page).to have_text(application_for_hospital_school.user.full_name)
    expect(page).not_to have_text(application_for_la_supply_teacher.user.full_name)
  end

  scenario "searching with employer name" do
    fill_in("Enter the participant ID", with: application_for_hospital_school.employer_name)
    click_on "Search"

    expect(page).to have_text(application_for_hospital_school.user.full_name)
    expect(page).not_to have_text(application_for_la_supply_teacher.user.full_name)
  end

  scenario "searching with application ID" do
    fill_in("Enter the participant ID", with: application_for_hospital_school.ecf_id)
    click_on "Search"

    expect(page).to have_text(application_for_hospital_school.user.full_name)
    expect(page).not_to have_text(application_for_la_supply_teacher.user.full_name)
  end

  scenario "filtering by employment type" do
    select "Hospital school", from: "Employment type"
    click_on "Search"

    expect(page).to have_text(application_for_hospital_school.user.full_name)
    expect(page).not_to have_text(application_for_la_supply_teacher.user.full_name)
  end

  scenario "filtering by referred by return to teaching adviser" do
    application_for_hospital_school.update!(employer_name: "Return to teaching adviser referral")

    select "Yes", from: "Referred by return to teaching adviser"
    click_on "Search"

    expect(page).to have_text(application_for_hospital_school.user.full_name)
    expect(page).to have_text(application_for_rtta_yes.user.full_name)
    expect(page).not_to have_text(application_for_la_supply_teacher.user.full_name)
    expect(page).not_to have_text(application_for_la_virtual_school.user.full_name)
    expect(page).not_to have_text(application_for_rtta_no.user.full_name)
  end

  scenario "filtering by cohort" do
    select "2021/22", from: "Cohort"
    click_on "Search"

    expect(page).to have_text(application_for_hospital_school.user.full_name)
    expect(page).not_to have_text(application_for_la_supply_teacher.user.full_name)
  end

  scenario "combining search and filters" do
    fill_in("Enter the participant ID", with: application_for_hospital_school.user.full_name)
    select "2021/22", from: "Cohort"
    click_on "Search"

    expect(page).to have_text(application_for_hospital_school.user.full_name)
    expect(page).not_to have_text(application_for_la_supply_teacher.user.full_name)

    select "2022/23", from: "Cohort"
    click_on "Search"
    expect(page).not_to have_text(application_for_hospital_school.user.full_name)
    expect(page).not_to have_text(application_for_la_supply_teacher.user.full_name)
  end
end
