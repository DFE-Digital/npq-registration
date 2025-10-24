require "rails_helper"

RSpec.feature "viewing application history", :versioning, type: :feature do
  include Helpers::AdminLogin

  let(:application) { create(:application) }

  before do
    sign_in_as(create(:admin))
  end

  context "when there are no changes to the application" do
    scenario "viewing application history" do
      visit npq_separation_admin_application_path(application)
      click_link "Application history"

      expect(page).to have_css(
        ".govuk-caption-m",
        text: "#{application.user.full_name}, #{application.course.name}, #{application.created_at.to_date.to_fs(:govuk_short)}",
      )
      expect(page).to have_css("h1", text: "Application history")

      expect(page).to have_content("No changes have been made to this application.")
    end
  end

  context "when there are changes to the application" do
    let(:application) { create(:application, :accepted, cohort:, lead_provider: LeadProvider.first) }
    let(:cohort) { create(:cohort, start_year: 2024) }
    let(:older_cohort) { create(:cohort, start_year: 2023) }

    before do
      PaperTrail.request.whodunnit = "test user"
      create(:schedule, cohort: older_cohort, course_group: application.course.course_group, identifier: application.schedule.identifier)
      Applications::ChangeCohort.new(application:, cohort_id: older_cohort.id).change_cohort
      Applications::ChangeLeadProvider.new(application:, lead_provider_id: LeadProvider.last.id).change_lead_provider
      Applications::ChangeFundingEligibility.new(application:, eligible_for_funding: true).change_funding_eligibility
      create(:declaration, application:)
      Applications::ChangeTrainingStatus.new(application:, training_status: Application.training_statuses[:deferred], reason: "other").change_training_status
    end

    scenario "viewing application history" do
      visit npq_separation_admin_applications_history_path(application)
      expect(page).to have_css("h2", text: "Cohort changed to [2023]")
      expect(page).to have_css("h2", text: "Schedule changed to [#{Schedule.last.name}]")
      expect(page).to have_content("by test user")
      expect(page).to have_css("h2", text: "Provider changed to [UCL Institute of Education]")
      expect(page).to have_css("h2", text: "Eligible for funding changed to [Yes]")
      expect(page).to have_css("li", text: "Status code changed to [marked_funded_by_policy]")
      expect(page).to have_css("h2", text: "Training status changed to [deferred]")
      expect(page).to have_css("div.govuk-inset-text", text: "Reason for training status change: other")
    end
  end
end
