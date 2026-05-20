require "rails_helper"

RSpec.feature "Happy journeys", :with_cohorts, :with_default_schedules, :with_default_school, type: :feature do
  include Helpers::JourneyAssertionHelper
  include Helpers::JourneyStepHelper
  include ApplicationHelper

  include_context "Stub Get An Identity Omniauth Responses"

  before do
    course_cohort = create(:course_cohort, course: create(:course, :headship), cohort: Cohort.find_by(identifier: "2026a"))
    create(:course_cohort_provider, course_cohort:, lead_provider: LeadProvider.find_by(name: "LLSE"))
    create(:course_cohort_provider, course_cohort:, lead_provider: LeadProvider.find_by(name: "Best Practice Network"))
  end

  context "when JavaScript is enabled", :js do
    scenario("registration journey changing cohort to one LeadProvider no longer supports (with JS)") { run_scenario(js: true) }
  end

  context "when JavaScript is disabled", :no_js do
    scenario("registration journey changing cohort to one LeadProvider no longer supports (without JS)") { run_scenario(js: false) }
  end

  def run_scenario(js:)
    stub_participant_validation_request

    navigate_to_page(path: "/", submit_form: false, axe_check: false) do
      page.click_button("Start now")
    end

    expect(page).not_to have_content("Before you start")

    choose_course_start_date

    expect_page_to_have(path: "/registration/provider-check", submit_form: true) do
      page.choose("Yes", visible: :all)
    end

    # TODO: aria-expanded
    expect_page_to_have(path: "/registration/teacher-catchment", axe_check: false, submit_form: true) do
      page.choose("Yes", visible: :all)
    end

    expect_page_to_have(path: "/registration/work-setting", submit_form: true) do
      page.choose("A school", visible: :all)
    end

    choose_a_school(js:, name: "open")

    expect_page_to_have(path: "/registration/choose-your-npq", submit_form: true) do
      page.choose("Headship", visible: :all)
    end

    expect_page_to_have(path: "/registration/ineligible-for-funding", submit_form: false) do
      page.click_link("Continue")
    end

    expect_page_to_have(path: "/registration/funding-your-npq", submit_form: true) do
      page.choose "My workplace is covering the cost", visible: :all
    end

    expect_page_to_have(path: "/registration/choose-your-provider", submit_form: true) do
      page.choose("Teach First", visible: :all)
    end

    expect_page_to_have(path: "/registration/share-provider", submit_form: true) do
      expect(page).to have_text("Sharing your NPQ information")
      page.check("Yes, I agree to share my information", visible: :all)
    end

    expect_page_to_have(path: "/registration/check-answers", submit_form: false) do
      expect_check_answers_page_to_have_answers(
        {
          "Course funding" => "My workplace is covering the cost",
          "Course start" => "Autumn 2026",
          "Course" => "Headship",
          "Provider" => "Teach First",
          "Workplace" => "open manchester school – street 1, manchester",
          "Work setting" => "A school",
          "Workplace in England" => "Yes",
        },
      )
      page.click_link("Change", href: "/registration/course-start-date/change")
    end

    # now change cohort

    expect_page_to_have(path: "/registration/course-start-date/change", submit_form: true) do
      page.choose("No, I already started in Spring", visible: :all)
    end

    expect_page_to_have(path: "/registration/provider-check", submit_form: true) do
      page.choose("Yes", visible: :all)
    end

    expect_page_to_have(path: "/registration/teacher-catchment", axe_check: false, submit_form: true) do
      page.choose("Yes", visible: :all)
    end

    expect_page_to_have(path: "/registration/work-setting", submit_form: true) do
      page.choose("A school", visible: :all)
    end

    choose_a_school(js:, name: "open", already_searched_for_workplace: true)

    expect_page_to_have(path: "/registration/choose-your-npq", submit_form: true) do
      page.choose("Headship", visible: :all)
    end

    expect_page_to_have(path: "/registration/ineligible-for-funding", submit_form: false) do
      page.click_link("Continue")
    end

    expect_page_to_have(path: "/registration/funding-your-npq", submit_form: true) do
      expect(page).to have_text("How are you funding your course?")
      page.choose "My workplace is covering the cost", visible: :all
    end

    expect(page).not_to have_text("Ambition Institute")
    expect(page).to have_text("Best Practice Network")
    expect(page).not_to have_text("Church of England")
    expect(page).to have_text("LLSE")
    expect(page).not_to have_text("National Institute of Teaching")
    expect(page).not_to have_text("Teach First")
    expect(page).not_to have_text("UCL Institute of Education")

    expect_page_to_have(path: "/registration/choose-your-provider", submit_form: true) do
      page.choose("Best Practice Network", visible: :all)
    end

    expect_page_to_have(path: "/registration/share-provider", submit_form: true) do
      expect(page).to have_text("Sharing your NPQ information")
      page.check("Yes, I agree to share my information", visible: :all)
    end

    expect_page_to_have(path: "/registration/check-answers", submit_form: false) do
      expect_check_answers_page_to_have_answers(
        {
          "Course funding" => "My workplace is covering the cost",
          "Course start" => "Spring 2026",
          "Course" => "Headship",
          "Provider" => "Best Practice Network",
          "Workplace" => "open manchester school – street 1, manchester",
          "Work setting" => "A school",
          "Workplace in England" => "Yes",
        },
      )
    end
  end
end
