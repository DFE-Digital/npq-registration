require "rails_helper"

RSpec.feature "Sad journeys", :no_js, :with_default_schedules, type: :feature do
  include Helpers::JourneyAssertionHelper
  include Helpers::JourneyStepHelper
  include ApplicationHelper

  include_context "Stub Get An Identity Omniauth Responses"

  before do
    navigate_to_page(path: "/", submit_form: false, axe_check: false) do
      page.click_button("Start now")
    end
  end

  steps_that_require_course = %w[
    check-answers
    choose-your-provider
    ehco-new-headteacher
    ehco-possible-funding
    funding-eligibility-maths
    funding-eligibility-senco
    funding-your-npq
    get-an-identity-callback
    ineligible-for-funding
    maths-eligibility-teaching-for-mastery
    maths-understanding-of-approach
    possible-funding
    senco-in-role
    senco-start-date
  ]

  RegistrationWizard::VALID_REGISTRATION_STEPS
    .excluding(:choose_your_npq)
    .map { |step| step.to_s.dasherize }.each do |step|
    scenario "Navigating directly to the #{step} page does not raise an error" do
      visit "/registration/#{step}"
      if steps_that_require_course.include?(step)
        expect(page).to have_current_path("/registration/course-start-date")
      else
        expect(page).to have_current_path("/registration/#{step}")
      end
    end
  end
end
