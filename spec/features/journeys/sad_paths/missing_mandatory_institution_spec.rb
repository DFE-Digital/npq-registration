require "rails_helper"

RSpec.feature "Sad journeys", :no_js, :with_cohorts, :with_default_schedules, type: :feature do
  include Helpers::JourneyAssertionHelper
  include Helpers::JourneyStepHelper

  include_context "with stubbed Teacher Auth OmniAuth responses"
  include_context "with stubbed Teaching Record System person API"

  # N.B. from this perspective there is no difference between manually
  # navigating and having two browser windows open
  scenario "when an unintended journey leaves mandatory institution missing" do
    # start a journey in window 1 that doesn't require an institution
    complete_journey_as_far_as_choosing_a_work_setting(
      course: "Headship",
      work_setting: "Another setting",
    )

    expect_page_to_have(path: "/registration/your-employment", submit_form: true) do
      page.choose("As a teacher employed by a local authority to teach in more than one school", visible: :all)
    end

    expect_page_to_have(path: "/registration/your-role", submit_form: true) do
      page.fill_in "What is your role?", with: "Teacher"
    end

    expect_page_to_have(path: "/registration/your-employer", submit_form: false) do
      page.fill_in "What organisation are you employed by?", with: "Local authority"
    end
    # if this journey was continued, it would result possible-funding but 'In review'

    # jump to a different journey, in practice often a user navigating another
    # window/tab. the previous answers on the other window are irrelevant here.
    # choose a setting that does require an institution, but don't set it
    navigate_to_page(path: "/registration/work-setting", submit_form: true) do
      page.choose("A school", visible: :all)
    end

    expect_page_to_have(path: "/registration/choose-school", submit_form: false)

    # back to window 1 (with the store work setting now changed from window 2)
    navigate_to_page(path: "/registration/your-employer", submit_form: true) do
      page.fill_in "What organisation are you employed by?", with: "Local authority"
    end

    expect_page_to_have(path: "/registration/choose-school", submit_form: false) do
      expect(page).to have_text("Your application requires details of your school.")
    end
  end
end
