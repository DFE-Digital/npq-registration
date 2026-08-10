require "rails_helper"

RSpec.feature "Happy journeys", :no_js, :with_cohorts, :with_default_schedules, :with_default_school, type: :feature do
  include Helpers::JourneyAssertionHelper
  include Helpers::JourneyStepHelper
  include ApplicationHelper

  include_context "with stubbed Teacher Auth OmniAuth responses"
  include_context "with stubbed Teaching Record System person API"

  scenario "does not offer courses no lead provider delivers in the chosen cohort" do
    navigate_to_page(path: "/", submit_form: false, axe_check: false) do
      page.click_button("Start now")
    end

    expect_page_to_have(path: "/registration/course-start-date", submit_form: true) do
      page.choose("No, I already started in Spring", visible: :all)
    end

    # Only Headship and EHCO have a lead provider in the Spring cohort
    expect(page).to have_current_path("/registration/choose-your-npq")
    expect(page).to have_text("Headship")
    expect(page).to have_text("Early headship coaching offer")
    expect(page).not_to have_text("Early years leadership")
    expect(page).not_to have_text("Leading literacy")
  end

  scenario "unfunded cohort registration journey" do
    navigate_to_page(path: "/", submit_form: false, axe_check: false) do
      page.click_button("Start now")
    end

    expect_page_to_have(path: "/registration/course-start-date", submit_form: true) do
      page.choose("No, I already started in Spring", visible: :all)
    end

    expect_page_to_have(path: "/registration/choose-your-npq", submit_form: true) do
      page.choose("Headship", visible: :all)
    end

    expect_page_to_have(path: "/registration/work-setting", submit_form: true) do
      page.choose("A school", visible: :all)
      page.choose("Primary school (5 to 11)", visible: :all)
    end

    choose_a_school(js: false, name: "open")

    expect_page_to_have(path: "/registration/ineligible-for-funding", submit_form: false) do
      expect(page).to have_content("You’re not eligible for scholarship funding for the Headship NPQ course as you have selected the Spring 2026 cohort.")
      page.click_link("Continue to register")
    end

    expect_page_to_have(path: "/registration/funding-your-npq", submit_form: true) do
      page.choose "I am paying", visible: :all
    end

    expect_page_to_have(path: "/registration/choose-your-provider", submit_form: true) do
      page.choose("LLSE", visible: :all)
    end

    expect_page_to_have(path: "/registration/share-provider", submit_form: true) do
      page.check("Yes, I agree to share my information", visible: :all)
    end

    check_back_journey_is_correct

    check_answers_log_in_and_submit do
      expect_check_answers_page_to_have_answers(
        {
          "DfE scholarship funding" => "Not eligible",
          "Cohort" => "Spring 2026",
          "Course" => "Headship",
          "Provider" => "LLSE",
          "Course funding" => "I am paying",
          "Work setting" => "Primary school (5 to 11)",
        },
      )
    end

    expect_applicant_reached_end_of_journey(course_start: "Spring 2026")

    application = Application.last
    expect(application.funded_place).to be(false)
    expect(application.eligible_for_funding).to be(false)
    expect(application.cohort.funding).to eq "zero"
  end
end
