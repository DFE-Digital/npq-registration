require "rails_helper"

RSpec.feature "Happy journeys", :no_js, :with_cohorts, :with_default_schedules, :with_default_school, type: :feature do
  include Helpers::JourneyAssertionHelper
  include Helpers::JourneyStepHelper

  scenario "changing from a school to Another setting" do
    complete_journey_as_far_as_choosing_a_work_setting(
      course: "Headship",
      work_setting: "Primary school (5 to 11)",
    )

    choose_a_school(js: false, name: "open")

    expect_page_to_have(path: "/registration/ineligible-for-funding", submit_form: false) do
      page.click_link "Continue to register"
    end

    expect_page_to_have(path: "/registration/funding-your-npq", submit_form: true) do
      page.choose "I am paying", visible: :all
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
          "Course funding" => "I am paying",
          "Cohort" => "Autumn 2026",
          "Course" => "Headship",
          "Provider" => "Teach First",
          "Workplace" => "open manchester school – street 1, manchester",
          "Work setting" => "Primary school (5 to 11)",
          "Working in England" => "Yes",
        },
      )
      expect(page).to have_content 'funding_eligiblity_status_code: "ineligible_establishment_type"'
      page.click_link("Change", href: "/registration/work-setting/change")
    end

    expect_page_to_have(path: "/registration/work-setting/change", submit_form: true) do
      page.choose("Another setting", visible: :all)
    end

    expect_page_to_have(path: "/registration/your-employment/change", submit_form: true) do
      page.choose("In an independent hospital education organisation", visible: :all)
    end

    expect_page_to_have(path: "/registration/your-employer/change", submit_form: true) do
      page.fill_in "What organisation are you employed by?", with: "Big company"
    end

    expect_page_to_have(path: "/registration/possible-funding/change", click_continue: false) do
      expect(page).to have_content "In review"
      click_button "Continue to register"
    end

    expect_page_to_have(path: "/registration/choose-your-provider/change", submit_form: true)

    expect_page_to_have(path: "/registration/share-provider/change", submit_form: true)

    expect_page_to_have(path: "/registration/check-answers", submit_form: false) do
      expect_check_answers_page_to_have_answers(
        {
          "Cohort" => "Autumn 2026",
          "Course" => "Headship",
          "DfE scholarship funding" => "In review",
          "Employer" => "Big company",
          "Employment type" => "In an independent hospital education organisation",
          "Provider" => "Teach First",
          "Work setting" => "Another setting",
          "Working in England" => "Yes",
        },
      )
      expect(page).to have_content 'funding_eligiblity_status_code: "subject_to_review"'
    end
  end
end
