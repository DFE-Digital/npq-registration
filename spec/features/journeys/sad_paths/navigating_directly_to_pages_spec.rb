require "rails_helper"

RSpec.feature "Sad journeys", :no_js, :with_cohorts, :with_default_schedules, type: :feature do
  include Helpers::JourneyAssertionHelper
  include Helpers::JourneyStepHelper
  include ApplicationHelper

  include_context "with stubbed Teacher Auth OmniAuth responses"
  include_context "with stubbed Teaching Record System person API"

  before do
    navigate_to_page(path: "/", submit_form: false, axe_check: false) do
      page.click_button("Start now")
    end
  end

  steps_that_do_not_need_the_journey_to_have_started = %i[
    start
    course_start_date
  ]

  steps_that_do_not_require_course = %i[
    check_funding
    funding_your_npq
    teacher_catchment
    ineligible_for_funding
    choose_your_npq
  ]

  context "with registration closed steps" do
    before { Flipper.disable(Feature::REGISTRATION_OPEN) }

    scenario "navigating directly to the closed registration page does not raise an error" do
      visit "/registration/closed"
      expect(page).to have_current_path("/registration/closed")
    end
  end

  context "with steps that do not require the journey to have started" do
    steps_that_do_not_need_the_journey_to_have_started
      .map { |step| step.to_s.dasherize }
      .each do |step|
      scenario "navigating directly to the #{step} page shows the step" do
        visit "/registration/#{step}"
        expect(page).to have_current_path("/registration/#{step}")
      end
    end
  end

  context "with steps that are before the course is chosen" do
    steps_that_do_not_require_course
    .map { |step| step.to_s.dasherize }
    .each do |step|
      context "when the journey has not been started" do
        scenario "navigating directly to the #{step} page redirects to the start page" do
          visit "/registration/#{step}"
          expect(page).to have_current_path("/")
        end
      end

      context "when the journey has been started" do
        before do
          choose_course_start_date
          expect_page_to_have(path: "/registration/check-funding", submit_form: false)
        end

        scenario "navigating directly to the #{step} page shows the step" do
          visit "/registration/#{step}"
          expect(page).to have_current_path("/registration/#{step}")
        end
      end
    end
  end

  context "with the other steps in the registration journey" do
    RegistrationWizard::VALID_REGISTRATION_STEPS
    .excluding(steps_that_do_not_need_the_journey_to_have_started)
    .excluding(steps_that_do_not_require_course)
    .excluding(:closed)
    .map { |step| step.to_s.dasherize }
    .each do |step|
      context "when the journey has not been started" do
        scenario "navigating directly to the #{step} page redirects to the start page" do
          visit "/registration/#{step}"
          expect(page).to have_current_path("/")
        end
      end

      context "when the journey has been started" do
        before do
          choose_course_start_date
          expect_page_to_have(path: "/registration/check-funding", submit_form: false)
        end

        scenario "navigating directly to the #{step} page redirects to the course start date page" do
          visit "/registration/#{step}"
          expect(page).to have_current_path("/registration/course-start-date")
        end
      end
    end
  end

  context "when navigating directly to the check answers and submit page after getting to the check answers page" do
    scenario "redirects to the continue to login page" do
      complete_journey_as_far_as_check_answers
      visit "/registration/check-answers-and-submit"

      expect_page_to_have(path: "/registration/continue-to-login", submit_form: false)
    end
  end
end
