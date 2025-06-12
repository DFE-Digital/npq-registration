require "rails_helper"

RSpec.feature "Listing and viewing applications", type: :feature do
  include Helpers::AdminLogin
  include Helpers::MailHelper

  let(:applications_per_page) { Pagy::DEFAULT[:limit] }
  let(:applications_in_order) { Application.order(created_at: :asc, id: :asc) }

  before do
    create_list(:application, applications_per_page + 1)
    sign_in_as(create(:admin))
  end

  scenario "viewing the list of applications" do
    visit(npq_separation_admin_applications_path)

    expect(page).to have_css("h1", text: "Applications")

    applications_in_order.limit(applications_per_page).each do |application|
      expect(page).to have_link(application.ecf_id, href: npq_separation_admin_application_path(application.id))
      expect(page).to have_link(application.user.full_name, href: npq_separation_admin_user_path(application.user))
      expect(page).to have_text(application.employer_name_to_display)
    end

    expect(page).to have_css(".govuk-pagination__item--current", text: 1)
  end

  scenario "navigating to the second page of applications" do
    visit(npq_separation_admin_applications_path)

    click_on("Next")

    expect(page).to have_css("table.govuk-table tbody tr", count: 1)
    expect(page).to have_css(".govuk-pagination__item--current", text: "2")
  end

  scenario "searching applications" do
    visit(npq_separation_admin_applications_path)

    fill_in "Find an application", with: applications_in_order[0].ecf_id
    click_on "Search"

    expect(page).to have_css("table.govuk-table tbody tr", count: 1)
    expect(page).to have_text(applications_in_order[0].ecf_id)
  end

  scenario "filtering applications by application status" do
    application = applications_in_order.last
    application.update! training_status: :deferred

    visit(npq_separation_admin_applications_path)
    select "Deferred", from: "Application status"
    click_on "Search"

    expect(page).to have_select("Application status", selected: "Deferred")
    expect(page).to have_css("table.govuk-table tbody tr", count: 1)
    expect(page).to have_text(application.ecf_id)
  end

  scenario "filtering applications by provider approval status" do
    application = applications_in_order.last
    application.update! lead_provider_approval_status: :accepted

    visit(npq_separation_admin_applications_path)
    select "Accepted", from: "Provider approval status"
    click_on "Search"

    expect(page).to have_select("Provider approval status", selected: "Accepted")
    expect(page).to have_css("table.govuk-table tbody tr", count: 1)
    expect(page).to have_text(application.ecf_id)
  end

  scenario "filtering applications by year of application" do
    cohort = create(:cohort, start_year: 2022)
    application = applications_in_order.last
    application.update!(cohort:)

    visit(npq_separation_admin_applications_path)
    select "2022 to 2023", from: "Year of application"
    click_on "Search"

    expect(page).to have_select("Year of application", selected: "2022 to 2023")
    expect(page).to have_css("table.govuk-table tbody tr", count: 1)
    expect(page).to have_text(application.ecf_id)
  end

  scenario "filtering applications by work setting" do
    application = applications_in_order.last
    application.update!(work_setting: "a_school")

    visit(npq_separation_admin_applications_path)
    select "A school", from: "Work setting"
    click_on "Search"

    expect(page).to have_select("Work setting", selected: "A school")
    expect(page).to have_css("table.govuk-table tbody tr", count: 1)
    expect(page).to have_text(application.ecf_id)
  end

  scenario "simultaneously filtering and searching applications" do
    application = applications_in_order.last

    search_with_results = application.user.full_name
    approval_status_with_results = "Pending"
    search_without_results = "no-match"
    approval_status_without_results = "Accepted"

    visit(npq_separation_admin_applications_path)

    fill_in "Find an application", with: search_with_results
    select approval_status_without_results, from: "Provider approval status"
    click_on "Search"
    expect(page).to have_text("No applications match the search and filters")

    fill_in "Find an application", with: search_without_results
    select approval_status_with_results, from: "Provider approval status"
    click_on "Search"
    expect(page).to have_text("No applications match the search and filters")

    fill_in "Find an application", with: search_with_results
    select approval_status_with_results, from: "Provider approval status"
    click_on "Search"
    expect(page).to have_css("table.govuk-table tbody tr", count: 1)
    expect(page).to have_text(application.ecf_id)
  end

  scenario "viewing application details" do
    visit(npq_separation_admin_applications_path)

    application = applications_in_order.first
    application.update!(
      eligible_for_funding: true,
      lead_provider_approval_status: :accepted,
      funding_eligiblity_status_code: 123,
      employment_type: :full_time,
      employer_name: "Employer name",
      employment_role: :headteacher,
    )

    click_link(application.ecf_id)

    expect(page).to have_css("h1", text: application.user.full_name)
    expect(page).to have_css("p", text: "User ID: #{application.user.ecf_id}")
    expect(page).to have_css("p", text: "Date of birth: #{application.user.date_of_birth.to_fs(:govuk_short)} | National Insurance: Not provided")
    expect(page).to have_css("p", text: "Email: #{application.user.email}")
    expect(page).to have_css("p", text: "TRN: #{application.user.trn} Not verified")

    summary_lists = all(".govuk-summary-list")

    expect(page).to have_css("h2", text: "Application overview")

    within(summary_lists[0]) do |summary_list|
      expect(summary_list).to have_summary_item("Application ID", application.ecf_id)
      expect(summary_list).to have_summary_item("Course", application.course.name)
      expect(summary_list).to have_summary_item("Course identifier", application.course.identifier)
      expect(summary_list).to have_summary_item("Course provider", application.lead_provider.name)
      expect(summary_list).to have_summary_item("Course provider approval status", application.lead_provider_approval_status.humanize)
      expect(summary_list).to have_summary_item("Training status", application.training_status)
      expect(summary_list).to have_summary_item("Created", application.created_at.to_fs(:govuk_short))
      expect(summary_list).to have_summary_item("Updated", application.updated_at.to_fs(:govuk_short))
    end

    expect(page).to have_css("h2", text: "Funding eligibility")

    within(summary_lists[1]) do |summary_list|
      expect(summary_list).to have_summary_item("Eligible for funding", "Yes")
      expect(summary_list).to have_summary_item("Funded place", "")
      expect(summary_list).to have_summary_item("Status code", application.funding_eligiblity_status_code.humanize)
      expect(summary_list).to have_summary_item("Schedule cohort", application.cohort.start_year)
      expect(summary_list).to have_summary_item("Funding choice", application.funding_choice&.capitalize)
      expect(summary_list).to have_summary_item("Notes", "No notes")
    end

    expect(page).to have_css("h2", text: "Workplace")

    within(summary_lists[2]) do |summary_list|
      expect(summary_list).to have_summary_item("Name", application.employer_name)
      expect(summary_list).to have_summary_item("UK Provider Reference Number (UKPRN)", application.ukprn)
      expect(summary_list).to have_summary_item("Unique reference number (URN)", application.school_urn)
      expect(summary_list).to have_summary_item("Headteacher status", application.headteacher_status.humanize)
      expect(summary_list).to have_summary_item("Employment type", application.employment_type.humanize)
      expect(summary_list).to have_summary_item("ITT Lead mentor", application.lead_mentor? ? "Yes" : "No")
      expect(summary_list).to have_summary_item("ITT provider", application.itt_provider.operating_name)
      expect(summary_list).to have_summary_item("Country", application.teacher_catchment_country)
    end

    expect(page).to have_css("h2", text: "Declarations")

    expect(page).to have_css("p", text: "No declarations")
  end

  scenario "viewing application details with declarations" do
    visit(npq_separation_admin_applications_path)

    application = Application.order(created_at: :asc, id: :asc).first
    started_declaration = create(:declaration, :from_ecf, application:)
    completed_declaration = create(:declaration, :completed, application:)
    payable_statement = create(:statement, :payable)
    payable_declaration = create(:declaration, :payable, application:, statement: payable_statement)
    paid_statement = create(:statement, :paid, declaration: payable_declaration)

    click_link(application.ecf_id)

    expect(page).to have_css("h2", text: "Declarations")

    summary_cards = all("[data-declarations] .govuk-summary-card")
    expect(summary_cards).to have_attributes(length: 3)

    within(summary_cards[0]) do |summary_card|
      expect(summary_card).to have_css(".govuk-summary-card__title", text: "Started (Submitted)")

      within(find(".govuk-summary-list")) do |summary_list|
        expect(summary_list).to have_summary_item("Declaration ID", started_declaration.ecf_id)
        expect(summary_list).to have_summary_item("Declaration date", started_declaration.declaration_date.to_fs(:govuk_short))
        expect(summary_list).to have_summary_item("Declaration cohort", started_declaration.cohort.start_year)
        expect(summary_list).to have_summary_item("Course provider", started_declaration.lead_provider.name)
        expect(summary_list).to have_summary_item("Created at", started_declaration.created_at.to_fs(:govuk_short))
        expect(summary_list).to have_summary_item("Updated at", started_declaration.updated_at.to_fs(:govuk_short))
        expect(summary_list).to have_summary_item("Statements", "")
      end
    end

    within(summary_cards[1]) do |summary_card|
      expect(summary_card).to have_css(".govuk-summary-card__title", text: "Completed (Submitted)")

      within(find(".govuk-summary-list")) do |summary_list|
        expect(summary_list).to have_summary_item("Declaration ID", "-")
        expect(summary_list).to have_summary_item("Declaration date", completed_declaration.declaration_date.to_fs(:govuk_short))
        expect(summary_list).to have_summary_item("Declaration cohort", completed_declaration.cohort.start_year)
        expect(summary_list).to have_summary_item("Course provider", completed_declaration.lead_provider.name)
        expect(summary_list).to have_summary_item("Created at", completed_declaration.created_at.to_fs(:govuk_short))
        expect(summary_list).to have_summary_item("Updated at", completed_declaration.updated_at.to_fs(:govuk_short))
        expect(summary_list).to have_summary_item("Statements", "")
      end
    end

    within(summary_cards[2]) do
      within(find(".govuk-summary-list")) do |summary_list|
        expect(summary_list).to have_summary_item(
          "Statements",
          "#{Date::MONTHNAMES[payable_statement.month]} #{payable_statement.year}" \
          "\n" \
          "#{Date::MONTHNAMES[paid_statement.month]} #{paid_statement.year}",
        )
      end
    end

    click_link("#{Date::MONTHNAMES[payable_statement.month]} #{payable_statement.year}")
    expect(page).to have_current_path(npq_separation_admin_finance_statement_path(payable_statement))

    visit(npq_separation_admin_application_path(application))
    click_link("#{Date::MONTHNAMES[paid_statement.month]} #{paid_statement.year}")
    expect(page).to have_current_path(npq_separation_admin_finance_statement_path(paid_statement))
  end

  scenario "viewing participant details" do
    visit(npq_separation_admin_applications_path)

    user = applications_in_order.first.user

    expect(page).to have_link(user.full_name, href: npq_separation_admin_user_path(user))
  end

  scenario "resending outcome to qualified teachers api" do
    outcome = create(:participant_outcome, :unsuccessfully_sent_to_qualified_teachers_api)

    visit npq_separation_admin_application_path(outcome.application_id)

    expect(page).to have_css("h1", text: outcome.user.full_name)

    within(".govuk-table tbody tr:first-of-type td:last-of-type") do |action_cell|
      expect(action_cell).to have_button("Resend")

      click_button("Resend")
    end

    expect(page).to have_css("h1", text: outcome.user.full_name)
    expect(page).to have_css(".govuk-notification-banner--success", text: /rescheduled/i)
  end

  scenario "changing lead provider approval status" do
    application = create(:application, :accepted)

    visit npq_separation_admin_application_path(application)

    expect(page).to have_css("h1", text: application.user.full_name)

    within(".govuk-summary-list__row", text: "Course provider approval status") do |summary_list_row|
      expect(summary_list_row).to have_text "Accepted"
      click_link("Change")
    end

    expect(page).to have_css("h1", text: "Are you sure you want to change the status to Pending?")
    click_button "Change status to Pending"

    expect(page).to have_css(".govuk-error-message", text: "Confirm you wish to change the status to Pending")
    choose "Yes", visible: :all
    click_button "Change status to Pending"

    expect(page).to have_css("h1", text: application.user.full_name)
    within(".govuk-summary-list__row", text: "Course provider approval status") do |summary_list_row|
      expect(summary_list_row).to have_text "Pending"
      expect(summary_list_row).not_to have_link("Change")
    end
  end

  scenario "changing training status" do
    application = create(:application, :accepted)
    create(:declaration, application:)

    visit npq_separation_admin_application_path(application)

    expect(page).to have_css("h1", text: application.user.full_name)

    within(".govuk-summary-list__row", text: "Training status") do |summary_list|
      expect(summary_list).to have_text "Active"
      click_on "Change"
    end

    expect(page).to have_css("h1", text: "Change training status")
    choose "Defer", visible: :all
    click_button "Continue"

    expect(page).to have_css(".govuk-error-message", text: "Choose a valid reason for the training status change")
    select Applications::ChangeTrainingStatus::REASON_OPTIONS["deferred"].first
    click_button "Continue"

    expect(page).to have_css("h1", text: application.user.full_name)
    within(".govuk-summary-list__row", text: "Training status") do |summary_list|
      expect(summary_list).to have_text "Deferred"
      click_on "Change"
    end

    expect(page).to have_css("h1", text: "Change training status")
    choose "Active", visible: :all
    click_button "Continue"

    expect(page).to have_css("h1", text: application.user.full_name)
    within(".govuk-summary-list__row", text: "Training status") do |summary_list|
      expect(summary_list).to have_text "Active"
    end
  end

  scenario "changing lead provider" do
    application = create(:application)

    visit npq_separation_admin_application_path(application)
    expect(page).to have_css("h1", text: application.user.full_name)

    within(".govuk-summary-list__row", text: application.lead_provider.name) do
      click_link("Transfer")
    end

    expect(page).to have_css("h1", text: "Transfer course provider")

    click_button "Continue"
    expect(page).to have_css(".govuk-error-message", text: "Choose a course provider")

    choose "Best Practice Network", visible: :all
    click_button "Continue"

    expect(page).to have_css("h1", text: application.user.full_name)
    expect(page).to have_summary_item("Course provider", "Best Practice Network")
  end

  scenario "changing eligibility for funding" do
    application = create(:application, :accepted)

    visit npq_separation_admin_application_path(application)

    expect(page).to have_css("h1", text: application.user.full_name)
    within(".govuk-summary-list__row", text: "Eligible for funding") do |summary_list_row|
      expect(summary_list_row).to have_text "No"
      click_link("Change")
    end

    expect(page).to have_css("h1", text: application.user.full_name)
    click_button "Continue"

    expect(page).to have_css(".govuk-error-message", text: "Choose whether the Application is eligible for funding")
    choose "Yes", visible: :all
    perform_enqueued_jobs { click_button "Continue" }

    expect_mail_to_have_been_sent(to: application.user.email, template_id: ApplicationFundingEligibilityMailer::ELIGIBLE_FOR_FUNDING_TEMPLATE)

    expect(page).to have_css("h1", text: application.user.full_name)
    within(".govuk-summary-list__row", text: "Eligible for funding") do |summary_list_row|
      expect(summary_list_row).to have_text "Yes"
      click_link("Change")
    end

    expect(page).to have_css("h1", text: application.user.full_name)
    choose "No", visible: :all
    click_button "Continue"

    expect(page).to have_css("h1", text: application.user.full_name)
    within(".govuk-summary-list__row", text: "Eligible for funding") do |summary_list_row|
      expect(summary_list_row).to have_text "No"
    end
  end

  scenario "changing schedule cohort" do
    application = create(:application, cohort: Cohort.first)
    create(:schedule, :npq_leadership_autumn, cohort: application.cohort)
    create(:schedule, :npq_leadership_spring, cohort: create(:cohort, start_year: 2025))

    visit npq_separation_admin_application_path(application)

    within(".govuk-summary-list__row", text: "Schedule cohort") do
      click_link("Change")
    end

    expect(page).to have_css("h1", text: "Choose a cohort")

    click_button "Continue"
    expect(page).to have_css(".govuk-error-message", text: "Choose a cohort")

    choose "2025", visible: :all
    click_button "Continue"

    within(".govuk-summary-list__row", text: "Schedule cohort") do |row|
      expect(row).to have_text("2025")
    end
  end

  scenario "adding and editing notes" do
    visit(npq_separation_admin_applications_path)

    application = applications_in_order.first

    click_link(application.ecf_id)

    within(".govuk-summary-list__row", text: "Notes") do
      click_on "Add note"
    end

    # check cancel
    click_on "Cancel"
    expect(page).to have_current_path(npq_separation_admin_application_path(application))

    # change for real
    within(".govuk-summary-list__row", text: "Notes") do
      click_on "Add note"
    end

    fill_in "Add a note about the changes to this registration", with: "Some notes"
    click_on "Add note"

    expect(page).to have_current_path(npq_separation_admin_application_path(application))
    within(".govuk-summary-list__row", text: "Notes") do
      expect(page).to have_text("Some notes")
    end

    within(".govuk-summary-list__row", text: "Notes") do
      click_on "Edit note"
    end
    fill_in "Edit the note about the changes to this registration", with: "Different notes"
    click_on "Edit note"

    expect(page).to have_current_path(npq_separation_admin_application_path(application))
    within(".govuk-summary-list__row", text: "Notes") do
      expect(page).to have_text("Different notes")
    end

    # check going straight to the note edit page
    visit(edit_npq_separation_admin_applications_notes_path(application))
    click_on "Cancel"
    expect(page).to have_current_path(npq_separation_admin_application_path(application))
  end
end
