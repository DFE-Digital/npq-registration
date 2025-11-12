require "rails_helper"

RSpec.feature "Sad journeys", type: :feature do
  include Helpers::JourneyAssertionHelper
  include Helpers::JourneyStepHelper

  include_context "Stub Get An Identity Omniauth Responses"

  # N.B. from this perspective there is no difference between manually
  # navigating and having two browser windows open
  scenario "when an unintended journey leaves mandatory institution missing" do
    # start a journey in window 1 that doesn't require an institution
    navigate_to_page(path: "/", submit_form: true, axe_check: false) do
      page.click_button("Start now")
    end

    expect_page_to_have(path: "/registration/course-start-date", submit_form: true) do
      page.choose("Yes", visible: :all)
    end

    expect_page_to_have(path: "/registration/provider-check", submit_form: true) do
      page.choose("Yes", visible: :all)
    end

    expect_page_to_have(path: "/registration/teacher-catchment", axe_check: false, submit_form: true) do
      page.choose("Yes", visible: :all)
    end

    expect_page_to_have(path: "/registration/work-setting", submit_form: true) do
      page.choose("Another setting", visible: :all)
    end

    expect_page_to_have(path: "/registration/your-employment", submit_form: true) do
      page.choose("As a teacher employed by a local authority to teach in more than one school", visible: :all)
    end

    expect_page_to_have(path: "/registration/your-role", submit_form: true) do
      page.fill_in "What is your role?", with: "Teacher"
    end

    expect_page_to_have(path: "/registration/your-employer", submit_form: true) do
      page.fill_in "What organisation are you employed by?", with: "Local authority"
    end

    expect_page_to_have(path: "/registration/choose-your-npq", submit_form: true) do
      page.choose("Headship", visible: :all)
    end

    expect_page_to_have(path: "/registration/possible-funding", submit_form: false)

    # jump to a different journey, in practice often a user navigating another
    # window/tab. the previous answers on the other window are irrelevant here.
    # choose a setting that does require an institution, but don't set it
    navigate_to_page(path: "/registration/work-setting", submit_form: true) do
      page.choose("A school", visible: :all)
    end

    expect_page_to_have(path: "/registration/choose-school", submit_form: false)

    # back to window 1 (with the store work setting now changed from window 2)
    navigate_to_page(path: "/registration/choose-your-npq", submit_form: true) do
      page.choose("Headship", visible: :all)
    end

    expect_page_to_have(path: "/registration/choose-school", submit_form: true)

    navigate_to_page(path: "/registration/share-provider", submit_form: true) do
      page.check("Yes, I agree to share my information", visible: :all)
    end

    expect_page_to_have(path: "/registration/choose-school", submit_form: true)
  end
end
