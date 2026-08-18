require "rails_helper"

RSpec.feature "Happy journeys", :with_cohorts, :with_default_schedules, :with_default_school, type: :feature do
  include Helpers::JourneyAssertionHelper
  include Helpers::JourneyStepHelper
  include ApplicationHelper

  include_context "with stubbed Teacher Auth OmniAuth responses"
  include_context "with stubbed Teaching Record System person API"

  before do
    course_cohort = CourseCohort.find_by(course: Course.find_by(identifier: "npq-headship"), cohort: Cohort.find_by(identifier: "2026a"))
    create(:course_cohort_provider, course_cohort:, lead_provider: LeadProvider.find_by(name: "Best Practice Network"))
  end

  context "with JS", :js do
    scenario("registration journey changing cohort to one LeadProvider no longer supports") { run_scenario(js: true) }
  end

  context "without JS", :no_js do
    scenario("registration journey changing cohort to one LeadProvider no longer supports") { run_scenario(js: false) }
  end

  def run_scenario(js:)
    complete_journey_as_far_as_choosing_a_work_setting(
      course: "Headship",
      work_setting: "Primary school (5 to 11)",
    )

    choose_a_school(js:, name: "open")

    expect_page_to_have(path: "/registration/ineligible-for-funding", submit_form: false) do
      page.click_link("Continue to register")
    end

    expect_page_to_have(path: "/registration/funding-your-npq", submit_form: true) do
      page.choose "My workplace is covering the cost", visible: :all
    end

    expect_page_to_have(path: "/registration/choose-your-provider", submit_form: true) do
      page.choose("Teach First", visible: :all)
    end

    expect_page_to_have(path: "/registration/share-provider", submit_form: true) do
      page.check("Yes, I agree to share my information", visible: :all)
    end

    expect_page_to_have(path: "/registration/check-answers", submit_form: false) do
      expect_check_answers_page_to_have_answers(
        {
          "DfE scholarship funding" => "Not eligible",
          "Course funding" => "My workplace is covering the cost",
          "Cohort" => "Autumn 2026",
          "Course" => "Headship",
          "Provider" => "Teach First",
          "Workplace" => "open manchester school – street 1, manchester",
          "Work setting" => "Primary school (5 to 11)",
          "Working in England" => "Yes",
        },
      )
      page.click_link("Change", href: "/registration/course-start-date/change")
    end

    # now change cohort

    expect_page_to_have(path: "/registration/course-start-date/change", submit_form: true) do
      page.choose("No, I already started in Spring", visible: :all)
    end

    expect_page_to_have(path: "/registration/choose-your-provider/change", submit_form: true) do
      expect(page).not_to have_text("Ambition Institute")
      expect(page).to have_text("Best Practice Network")
      expect(page).not_to have_text("Church of England")
      expect(page).to have_text("LLSE")
      expect(page).not_to have_text("National Institute of Teaching")
      expect(page).not_to have_text("Teach First")
      expect(page).not_to have_text("UCL Institute of Education")

      page.choose("Best Practice Network", visible: :all)
    end

    expect_page_to_have(path: "/registration/share-provider/change", submit_form: true) do
      expect(page).to have_text("Sharing your NPQ information")
      page.check("Yes, I agree to share my information", visible: :all)
    end

    expect_page_to_have(path: "/registration/check-answers", submit_form: false) do
      expect_check_answers_page_to_have_answers(
        {
          "DfE scholarship funding" => "Not eligible",
          "Course funding" => "My workplace is covering the cost",
          "Cohort" => "Spring 2026",
          "Course" => "Headship",
          "Provider" => "Best Practice Network",
          "Workplace" => "open manchester school – street 1, manchester",
          "Work setting" => "Primary school (5 to 11)",
          "Working in England" => "Yes",
        },
      )
    end
  end
end
