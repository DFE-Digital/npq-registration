require "rails_helper"

RSpec.feature "Happy journeys", :no_js, :with_cohorts, :with_default_schedules, :with_default_school, type: :feature do
  include Helpers::JourneyAssertionHelper
  include Helpers::JourneyStepHelper
  include ApplicationHelper

  include_context "with stubbed Teacher Auth OmniAuth responses"
  include_context "with stubbed Teaching Record System person API"

  scenario "When already logged in" do
    navigate_to_page(path: "/", submit_form: false) do
      page.click_button("Sign in")
    end

    complete_journey_as_far_as_choosing_a_work_setting(
      course: "Headship",
      work_setting: "Secondary school (11 to 16)",
    )

    choose_a_school(js: false, name: "open")

    expect_page_to_have(path: "/registration/ineligible-for-funding", submit_form: false) do
      page.click_link("Continue to register")
    end

    expect_page_to_have(path: "/registration/funding-your-npq", submit_form: true) do
      expect(page).to have_text("How are you funding your course?")
      page.choose "I am paying", visible: :all
    end

    expect_page_to_have(path: "/registration/choose-your-provider", submit_form: true) do
      expect(page).to have_text("Select your provider")
      page.choose("Teach First", visible: :all)
    end

    expect_page_to_have(path: "/registration/share-provider", submit_form: true) do
      expect(page).to have_text("Sharing your NPQ information")
      page.check("Yes, I agree to share my information", visible: :all)
    end

    # check_back_journey_is_correct # FIXME: this currently fails

    expect_page_to_have(path: "/registration/check-answers-and-submit", submit_button_text: "Submit", submit_form: true) do
      expect_check_answers_page_to_have_answers(
        {
          "Course funding" => "I am paying",
          "Cohort" => "Autumn 2026",
          "Course" => "Headship",
          "DfE scholarship funding" => "Not eligible",
          "Provider" => "Teach First",
          "Workplace" => "open manchester school – street 1, manchester",
          "Work setting" => "Secondary school (11 to 16)",
          "Working in England" => "Yes",
        },
      )
    end

    expect_applicant_reached_end_of_journey
  end
end
