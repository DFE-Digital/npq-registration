require "rails_helper"

RSpec.feature "Happy journeys", :no_js, :with_cohorts, :with_default_schedules, :with_default_school, type: :feature do
  include Helpers::JourneyAssertionHelper
  include Helpers::JourneyStepHelper
  include ApplicationHelper

  include_context "with stubbed Teacher Auth OmniAuth responses"
  include_context "with stubbed Teaching Record System person API"

  scenario "the registration journey starts" do
    navigate_to_page(path: "/", submit_form: false, axe_check: false) do
      expect(page).to have_text("Before you start")
      page.click_button("Start now with Teacher Auth")
    end

    choose_course_start_date
    expect(User.last.attributes).to include(user_attributes_from_stubbed_callback_response)

    expect_page_to_have(path: "/registration/provider-check", submit_form: true) do
      page.choose("Yes", visible: :all)
    end

    expect_page_to_have(path: "/registration/teacher-catchment", axe_check: false, submit_form: true) do
      page.choose("Yes", visible: :all)
    end

    expect_page_to_have(path: "/registration/work-setting", submit_form: true) do
      page.choose("A school", visible: :all)
    end

    choose_a_school(js: false, name: "open")

    expect_page_to_have(path: "/registration/choose-your-npq", submit_form: true) do
      page.choose("Headship", visible: :all)
    end

    expect_page_to_have(path: "/registration/ineligible-for-funding", submit_form: false) do
      page.click_link("Continue")
    end

    expect_page_to_have(path: "/registration/funding-your-npq", submit_form: true) do
      page.choose "My trust is paying", visible: :all
    end

    expect_page_to_have(path: "/registration/choose-your-provider", submit_form: true) do
      page.choose("Teach First", visible: :all)
    end

    expect_page_to_have(path: "/registration/share-provider", submit_form: true) do
      page.check("Yes, I agree to share my information", visible: :all)
    end

    expect_page_to_have(path: "/registration/check-answers", submit_button_text: "Submit", submit_form: true) do
      expect_check_answers_page_to_have_answers(
        {
          "Course start" => course_start_cohort_description,
          "Course" => "Headship",
          "Provider" => "Teach First",
          "Workplace" => "open manchester school – street 1, manchester",
          "Course funding" => "My trust is paying",
          "Work setting" => "A school",
          "Workplace in England" => "Yes",
        },
      )
    end

    expect_applicant_reached_end_of_journey

    expect(retrieve_latest_application_user_data).to include(user_attributes_from_stubbed_callback_response)
  end
end
