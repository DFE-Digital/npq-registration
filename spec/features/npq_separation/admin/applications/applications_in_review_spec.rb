require "rails_helper"

RSpec.feature "Applications in review", type: :feature do
  include Helpers::AdminLogin

  let(:cohort_21) { create :cohort, :without_funding_cap, start_year: 2021 }
  let(:cohort_22) { create :cohort, :without_funding_cap, start_year: 2022 }

  let!(:normal_application)                         { create(:application, :with_random_user) }
  let!(:application_for_hospital_school)            { create(:application, :with_random_user, :manual_review, created_at: 10.days.ago, employment_type: "hospital_school", employer_name: Faker::Company.name, cohort: cohort_21, referred_by_return_to_teaching_adviser: "yes") }
  let!(:application_for_la_supply_teacher)          { create(:application, :with_random_user, :manual_review, created_at: 9.days.ago, employment_type: "local_authority_supply_teacher", cohort: cohort_22, referred_by_return_to_teaching_adviser: "no") }
  let!(:application_for_la_virtual_school)          { create(:application, :with_random_user, :manual_review, created_at: 8.days.ago, employment_type: "local_authority_virtual_school") }
  let!(:application_for_lead_mentor)                { create(:application, :with_random_user, :manual_review, created_at: 7.days.ago, employment_type: "local_authority_virtual_school") }
  let!(:application_for_young_offender_institution) { create(:application, :with_random_user, :manual_review, created_at: 6.days.ago, employment_type: "young_offender_institution") }
  let!(:application_for_other)                      { create(:application, :with_random_user, :manual_review, created_at: 5.days.ago, employment_type: "other") }
  let!(:application_for_rtta_yes)                   { create(:application, :with_random_user, :manual_review, created_at: 4.days.ago, referred_by_return_to_teaching_adviser: "yes", school: nil, works_in_school: false) }
  let!(:application_for_rtta_no)                    { create(:application, :with_random_user, created_at: 3.days.ago, referred_by_return_to_teaching_adviser: "no") }
  let!(:application_eligible_for_funding)           { create(:application, :with_random_user, :manual_review, :eligible_for_funding, created_at: 11.days.ago, employment_type: "other") }
  let!(:application_with_funding_decision)          { create(:application, :with_random_user, :accepted, :without_funded_place, created_at: 12.days.ago, employment_type: "hospital_school", review_status: "decision_made") }

  let(:serialized_application) { { application: 1 } }

  before do
    sign_in_as create(:admin)
    visit npq_separation_admin_applications_path
    click_on "In review"
  end

  scenario "listing" do
    rows = [
      application_with_funding_decision,
      application_eligible_for_funding,
      application_for_hospital_school,
      application_for_la_supply_teacher,
      application_for_la_virtual_school,
      application_for_lead_mentor,
      application_for_young_offender_institution,
      application_for_other,
      application_for_rtta_yes,
    ].map do |application|
      [
        application.created_at.to_fs(:govuk_short),
        [application.user.full_name, application.employment_type.try(:humanize), application.employer_name].compact.join,
        application.review_status,
        application.eligible_for_funding ? "Yes" : "No",
        application.lead_provider_approval_status.humanize,
        application.notes.to_s,
        "View",
      ]
    end

    expect(page).to have_table(rows:)
    expect(page).not_to have_text normal_application.user.full_name
    expect(page).not_to have_text application_for_rtta_no.user.full_name
  end

  scenario "default filters" do
    expect(page).to have_checked_field("Show registrations without a funding decision", visible: :all)
  end

  scenario "searching with User ID" do
    fill_in("Enter the User ID", with: application_for_hospital_school.user.ecf_id)
    click_on "Search"

    expect(page).to have_text(application_for_hospital_school.user.full_name)
    expect(page).not_to have_text(application_for_la_supply_teacher.user.full_name)
  end

  scenario "searching with User ID when the application has no school relation" do
    fill_in("Enter the User ID", with: application_for_rtta_yes.user.ecf_id)
    click_on "Search"

    expect(page).to have_text(application_for_rtta_yes.user.full_name)
    expect(page).not_to have_text(application_for_hospital_school.user.full_name)
    expect(page).not_to have_text(application_for_la_supply_teacher.user.full_name)
  end

  scenario "searching with user name" do
    fill_in("Enter the User ID", with: application_for_hospital_school.user.full_name)
    click_on "Search"

    expect(page).to have_text(application_for_hospital_school.user.full_name)
    expect(page).not_to have_text(application_for_la_supply_teacher.user.full_name)
  end

  scenario "searching with user email" do
    fill_in("Enter the User ID", with: application_for_hospital_school.user.email)
    click_on "Search"

    expect(page).to have_text(application_for_hospital_school.user.full_name)
    expect(page).not_to have_text(application_for_la_supply_teacher.user.full_name)
  end

  scenario "searching with employer name" do
    fill_in("Enter the User ID", with: application_for_hospital_school.employer_name)
    click_on "Search"

    expect(page).to have_text(application_for_hospital_school.user.full_name)
    expect(page).not_to have_text(application_for_la_supply_teacher.user.full_name)
  end

  scenario "searching with application ID" do
    fill_in("Enter the User ID", with: application_for_hospital_school.ecf_id)
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

  scenario "filtering by eligible for funding" do
    select "No", from: "Eligible for funding"
    click_on "Search"

    expect(page).to have_text(application_for_la_supply_teacher.user.full_name)
    expect(page).not_to have_text(application_eligible_for_funding.user.full_name)

    select "Yes", from: "Eligible for funding"
    click_on "Search"

    expect(page).not_to have_text(application_for_la_supply_teacher.user.full_name)
    expect(page).to have_text(application_eligible_for_funding.user.full_name)
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

  scenario "filtering by registrations without a funding decision" do
    uncheck "Show registrations without a funding decision", visible: :all
    click_on "Search"

    expect(page).to have_unchecked_field("Show registrations without a funding decision", visible: :all)
    expect(page).not_to have_text(application_for_la_supply_teacher.user.full_name)
    expect(page).to have_text(application_with_funding_decision.user.full_name)
  end

  scenario "filtering by cohort" do
    select "2021 to 2022", from: "Year of registration"
    click_on "Search"

    expect(page).to have_text(application_for_hospital_school.user.full_name)
    expect(page).not_to have_text(application_for_la_supply_teacher.user.full_name)
  end

  scenario "filtering by review status" do
    select "Needs review", from: "Review status"
    click_on "Search"

    expect(page).to have_text application_for_hospital_school.user.full_name
    expect(page).not_to have_text application_with_funding_decision.user.full_name

    select "Decision made", from: "Review status"
    click_on "Search"

    expect(page).to have_text application_with_funding_decision.user.full_name
    expect(page).not_to have_text application_for_hospital_school.user.full_name
  end

  scenario "combining search and filters" do
    fill_in("Enter the User ID", with: application_for_hospital_school.user.full_name)
    select "2021 to 2022", from: "Year of registration"
    click_on "Search"

    expect(page).to have_text(application_for_hospital_school.user.full_name)
    expect(page).not_to have_text(application_for_la_supply_teacher.user.full_name)

    select "2022 to 2023", from: "Year of registration"
    click_on "Search"
    expect(page).not_to have_text(application_for_hospital_school.user.full_name)
    expect(page).not_to have_text(application_for_la_supply_teacher.user.full_name)
  end

  scenario "viewing an application" do
    allow(API::ApplicationSerializer).to receive(:render_as_hash).and_return(serialized_application)
    application = application_with_funding_decision.reload
    application.user.update! uid: SecureRandom.uuid

    within("tr", text: application.user.full_name) do
      click_link("View")
    end

    expect(page).to have_css(
      ".govuk-caption-m",
      text: "#{application.user.full_name}, #{application.course.name}, #{application.created_at.to_date.to_fs(:govuk_short)}",
    )
    expect(page).to have_css("h1", text: "Application details")

    summary_lists = all(".govuk-summary-list")

    expect(page).to have_css("h2", text: "Overview")
    within(summary_lists[0]) do |summary_list|
      expect(summary_list).to have_summary_item("Name", application.user.full_name)
      expect(summary_list).to have_summary_item("Course", application.course.name)
      expect(summary_list).to have_summary_item("Provider", application.lead_provider.name)
      expect(summary_list).to have_summary_item("Provider approval status", application.lead_provider_approval_status.humanize)
    end

    expect(page).to have_css("h2", text: "Funding details")
    within(summary_lists[1]) do |summary_list|
      expect(summary_list).to have_summary_item("Review status", "Decision made")
      expect(summary_list).to have_summary_item("Eligible for funding", "No")
      expect(summary_list).to have_summary_item("Funded place", "No")
      expect(summary_list).to have_summary_item("Notes", "No notes")
    end

    expect(page).to have_css("h2", text: "Work details")
    within(summary_lists[2]) do |summary_list|
      expect(summary_list).to have_summary_item("Works in England", "Yes")
      expect(summary_list).to have_summary_item("Work setting", application.work_setting)
      expect(summary_list).to have_summary_item("Employment type", application.employment_type.humanize)
      expect(summary_list).to have_summary_item("Employer name", application.employer_name)
      expect(summary_list).to have_summary_item("Role", application.employment_role)
    end

    expect(page).to have_css("h2", text: "Schedule")
    within(summary_lists[3]) do |summary_list|
      expect(summary_list).to have_summary_item("Cohort", application.cohort.name)
      expect(summary_list).to have_summary_item("Schedule identifier", application.schedule.identifier)
    end

    expect(page).to have_css("h2", text: "Registration details")
    within(summary_lists[4]) do |summary_list|
      expect(summary_list).to have_summary_item("User ID", application.user.ecf_id)
      expect(summary_list).to have_summary_item("Application ID", application.ecf_id)
      expect(summary_list).to have_summary_item("Registration submission date", application.created_at.to_fs(:govuk_short))
      expect(summary_list).to have_summary_item("Last updated date", application.updated_at.to_fs(:govuk_short))
    end

    find("summary", text: "View registration as it appears on the provider API V3").click
    expect(page).to have_text JSON.pretty_generate(serialized_application)

    # check side nav

    within "#side-navigation" do
      click_link "Application details"
      expect(page).to have_current_path(npq_separation_admin_application_review_path(application))
    end

    visit npq_separation_admin_application_review_path(application)

    within "#side-navigation" do
      click_link "Application history"
      expect(page).to have_current_path(npq_separation_admin_applications_reviews_history_path(application))
    end
  end

  scenario "adding and editing notes" do
    within("tr", text: application_for_hospital_school.user.full_name) do
      click_link("View")
    end

    within(".govuk-summary-list__row", text: "Notes") do
      click_on "Add note"
    end

    # check cancel
    click_on "Cancel"
    expect(page).to have_current_path(npq_separation_admin_application_review_path(application_for_hospital_school))

    # change for real
    within(".govuk-summary-list__row", text: "Notes") do
      click_on "Add note"
    end

    fill_in "Add a note about the changes to this registration", with: "Some notes"
    click_on "Add note"

    expect(page).to have_current_path(npq_separation_admin_application_review_path(application_for_hospital_school))
    within(".govuk-summary-list__row", text: "Notes") do
      expect(page).to have_text("Some notes")
    end

    within(".govuk-summary-list__row", text: "Notes") do
      click_on "Edit note"
    end

    fill_in "Edit the note about the changes to this registration", with: "Different notes"
    click_on "Edit note"

    expect(page).to have_current_path(npq_separation_admin_application_review_path(application_for_hospital_school))
    within(".govuk-summary-list__row", text: "Notes") do
      expect(page).to have_text("Different notes")
    end

    # check going straight to the note edit page
    visit(edit_npq_separation_admin_applications_notes_path(application_for_hospital_school))
    click_on "Cancel"
    expect(page).to have_current_path(npq_separation_admin_application_path(application_for_hospital_school))
  end

  scenario "viewing user details" do
    application = create(:application, :manual_review)

    visit npq_separation_admin_application_review_path(application)

    within(".govuk-summary-card", text: "Overview") do
      within(".govuk-summary-list__row", text: "Name") do
        expect(page).to have_text(application.user.full_name)
        click_link("View user")
      end
    end

    expect(page).to have_current_path(npq_separation_admin_user_path(application.user))
    expect(page).to have_css("h1", text: application.user.full_name)

    within(".govuk-summary-card", text: application.course.name) do
      click_link("View full application")
    end

    expect(page).to have_current_path(npq_separation_admin_application_path(application))

    within(first(".govuk-summary-list__row", text: "Name")) do
      expect(page).to have_text(application.user.full_name)
    end
  end

  scenario "Applications should display in correct order" do
    first_record = application_for_hospital_school.user.full_name
    second_record = application_for_young_offender_institution.user.full_name
    expect(page).to have_text(/#{first_record}.*#{second_record}/m)
  end

  scenario "default sort order shows oldest submissions first" do
    # Default sort should be ASC (oldest first)
    # application_with_funding_decision created 12 days ago (oldest in review)
    # application_for_young_offender_institution created 6 days ago (newest in default view)
    first_record = application_with_funding_decision.user.full_name
    last_record = application_for_rtta_yes.user.full_name # created 4 days ago

    expect(page).to have_text(/#{first_record}.*#{last_record}/m)
  end

  scenario "sorting by oldest submissions first" do
    select "Oldest submissions first", from: "Sort by"
    click_on "Sort"

    # Should show oldest first (ASC order)
    first_record = application_with_funding_decision.user.full_name # 12 days ago
    last_record = application_for_rtta_yes.user.full_name # 4 days ago

    expect(page).to have_text(/#{first_record}.*#{last_record}/m)
  end

  scenario "sorting by newest submissions first" do
    select "Newest submissions first", from: "Sort by"
    click_on "Sort"

    # Should show newest first (DESC order)
    first_record = application_for_rtta_yes.user.full_name # 4 days ago
    last_record = application_with_funding_decision.user.full_name # 12 days ago

    expect(page).to have_text(/#{first_record}.*#{last_record}/m)
  end

  scenario "sort parameter persists when combined with other filters" do
    # Apply a filter first
    select "Hospital school", from: "Employment type"
    click_on "Search"

    expect(page).to have_text(application_for_hospital_school.user.full_name)
    expect(page).to have_text(application_with_funding_decision.user.full_name)

    # Now apply DESC sort
    select "Newest submissions first", from: "Sort by"
    click_on "Sort"

    # Should maintain the filter and apply DESC sort
    # application_for_hospital_school created 10 days ago
    # application_with_funding_decision created 12 days ago
    first_record = application_for_hospital_school.user.full_name
    last_record = application_with_funding_decision.user.full_name

    expect(page).to have_text(/#{first_record}.*#{last_record}/m)
    expect(page).to have_select("Employment type", selected: "Hospital school")
  end

  scenario "switching between sort orders" do
    # Start with DESC
    select "Newest submissions first", from: "Sort by"
    click_on "Sort"

    first_record_desc = application_for_rtta_yes.user.full_name # 4 days ago
    expect(page).to have_text(/#{first_record_desc}/)

    # Switch to ASC
    select "Oldest submissions first", from: "Sort by"
    click_on "Sort"

    first_record_asc = application_with_funding_decision.user.full_name # 12 days ago
    last_record_asc = application_for_rtta_yes.user.full_name # 4 days ago

    expect(page).to have_text(/#{first_record_asc}.*#{last_record_asc}/m)
  end
end
