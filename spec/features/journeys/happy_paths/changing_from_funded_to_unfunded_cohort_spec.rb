require "rails_helper"

RSpec.feature "Happy journeys", :no_js, :with_cohorts, :with_default_schedules, type: :feature do
  include Helpers::JourneyAssertionHelper
  include Helpers::JourneyStepHelper
  include ApplicationHelper

  scenario "registration journey changing from a funded cohort to an unfunded cohort" do
    complete_journey_as_far_as_choosing_a_work_setting(
      course: "Senior leadership",
      work_setting: "Other",
    )

    expect_page_to_have(path: "/registration/referred-by-return-to-teaching-adviser", submit_form: true) do
      page.choose("Yes", visible: :all)
    end

    expect_page_to_have(path: "/registration/possible-funding", submit_form: true)

    expect_page_to_have(path: "/registration/choose-your-provider", submit_form: true) do
      page.choose("Teach First", visible: :all)
    end

    expect_page_to_have(path: "/registration/share-provider", submit_form: true) do
      page.check("Yes, I agree to share my information", visible: :all)
    end

    page.click_link("Change", href: "/registration/course-start-date/change")

    expect_page_to_have(path: "/registration/course-start-date/change", submit_form: true) do
      page.choose("No, I already started in Spring", visible: :all)
    end

    expect_page_to_have(path: "/registration/choose-your-npq/change", submit_form: true) do
      page.choose("Headship", visible: :all)
    end

    expect_page_to_have(path: "/registration/work-setting/change", submit_form: true)

    expect_page_to_have(path: "/registration/referred-by-return-to-teaching-adviser/change", submit_form: true)

    expect_page_to_have(path: "/registration/ineligible-for-funding/change", submit_form: false) do
      page.click_link("Continue to register")
    end

    expect_page_to_have(path: "/registration/funding-your-npq", submit_form: true) do
      expect(page).to have_text("How are you funding your course?")
      page.choose("I am paying", visible: :all)
    end

    expect_page_to_have(path: "/registration/choose-your-provider", submit_form: true) do
      page.choose("LLSE", visible: :all)
    end

    expect_page_to_have(path: "/registration/share-provider", submit_form: true)

    expect_page_to_have(path: "/registration/check-answers", submit_form: false) do
      expect_check_answers_page_to_have_answers(
        {
          "Cohort" => "Spring 2026",
          "Course funding" => "I am paying",
          "Course" => "Headship",
          "DfE scholarship funding" => "Not eligible",
          "Provider" => "LLSE",
          "Referred by return to teaching adviser" => "Yes",
          "Work setting" => "Other",
          "Working in England" => "Yes",
        },
      )
      expect(page).to have_content 'funding_eligiblity_status_code: "unfunded_cohort"'
    end
  end
end
