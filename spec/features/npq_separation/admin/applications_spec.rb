require "rails_helper"

RSpec.feature "Listing and viewing applications", type: :feature do
  include Helpers::AdminLogin

  let(:applications_per_page) { Pagy::DEFAULT[:limit] }
  let(:applications_in_order) { Application.order(created_at: :asc) }

  before do
    create_list(:application, applications_per_page + 1)
    sign_in_as(create(:admin))
  end

  scenario "viewing the list of applications" do
    visit(npq_separation_admin_applications_path)

    expect(page).to have_css("h1", text: "All applications")

    applications_in_order.limit(applications_per_page).each do |application|
      expect(page).to have_link(application.ecf_id, href: npq_separation_admin_application_path(application.id))
      expect(page).to have_link(application.user.full_name, href: npq_separation_admin_user_path(application.user))
      expect(page).to have_link(application.school.name, href: npq_separation_admin_school_path(application.school))
    end

    expect(page).to have_css(".govuk-pagination__item--current", text: 1)
  end

  scenario "navigating to the second page of applications" do
    visit(npq_separation_admin_applications_path)

    click_on("Next")

    expect(page).to have_css("table.govuk-table tbody tr", count: 1)
    expect(page).to have_css(".govuk-pagination__item--current", text: "2")
  end

  scenario "viewing application details" do
    visit(npq_separation_admin_applications_path)

    application = Application.order(created_at: :asc).first
    application.update!(
      eligible_for_funding: true,
      lead_provider_approval_status: :accepted,
      funding_eligiblity_status_code: 123,
      employment_type: :full_time,
      employer_name: "Employer name",
      employment_role: :headteacher,
    )

    click_link(application.ecf_id)

    expect(page).to have_css("h1", text: "Application for #{application.user.full_name}")

    summary_lists = all(".govuk-summary-list")

    expect(page).to have_css("h2", text: "Application details")

    within(summary_lists[0]) do |summary_list|
      expect(summary_list).to have_summary_item("Application ID", application.id)
      expect(summary_list).to have_summary_item("ECF ID", application.ecf_id)
      expect(summary_list).to have_summary_item("User ID", application.user.id)
      expect(summary_list).to have_summary_item("Email", application.user.email)
      expect(summary_list).to have_summary_item("TRN", application.user.trn)
      expect(summary_list).to have_summary_item("TRN validated", "No")
      expect(summary_list).to have_summary_item("Course name", application.course.name)
      expect(summary_list).to have_summary_item("Lead provider name", application.lead_provider.name)
      expect(summary_list).to have_summary_item("Lead provider approval status", application.lead_provider_approval_status.humanize)
      expect(summary_list).to have_summary_item("Created at", application.created_at.to_fs(:govuk_short))
      expect(summary_list).to have_summary_item("Updated at", application.updated_at.to_fs(:govuk_short))
    end

    expect(page).to have_css("h2", text: "Employment details")

    within(summary_lists[1]) do |summary_list|
      expect(summary_list).to have_summary_item("School URN", application.school_urn)
      expect(summary_list).to have_summary_item("School UKPRN", application.school.ukprn)
      expect(summary_list).to have_summary_item("Private Childcare Provider URN", "-")
      expect(summary_list).to have_summary_item("Headteacher status", application.headteacher_status)
      expect(summary_list).to have_summary_item("Employment type", application.employment_type.humanize)
      expect(summary_list).to have_summary_item("Employer name", application.employer_name)
      expect(summary_list).to have_summary_item("Employment role", application.employment_role.humanize)
      expect(summary_list).to have_summary_item("ITT Lead mentor", application.lead_mentor? ? "Yes" : "No")
      expect(summary_list).to have_summary_item("ITT provider", application.itt_provider.operating_name)
      expect(summary_list).to have_summary_item("Country", application.teacher_catchment_country)
    end

    expect(page).to have_css("h2", text: "Funding eligibility")

    within(summary_lists[2]) do |summary_list|
      expect(summary_list).to have_summary_item("Eligible for funding", "Yes")
      expect(summary_list).to have_summary_item("Funded place", "")
      expect(summary_list).to have_summary_item("Funding eligibility status code", application.funding_eligiblity_status_code.humanize)
      expect(summary_list).to have_summary_item("Primary establishment", "No")
      expect(summary_list).to have_summary_item("Number of pupils", application.number_of_pupils)
      expect(summary_list).to have_summary_item("Targeted support funding primary plus eligibility", "No")
      expect(summary_list).to have_summary_item("Targeted delivery funding eligibility", "No")
      expect(summary_list).to have_summary_item("Funding choice", application.funding_choice&.capitalize)
      expect(summary_list).to have_summary_item("Schedule Cohort", application.cohort.start_year)
      expect(summary_list).to have_summary_item("Schedule identifier", "-")
      expect(summary_list).to have_summary_item("Notes", "No notes")
    end
  end

  scenario "viewing participant details" do
    visit(npq_separation_admin_applications_path)

    user = applications_in_order.first.user

    expect(page).to have_link(user.full_name, href: npq_separation_admin_user_path(user))
  end

  scenario "viewing school details" do
    visit(npq_separation_admin_applications_path)

    school = applications_in_order.first.school

    click_link(school.name)

    expect(page).to have_css("h1", text: school.name)
  end
end
