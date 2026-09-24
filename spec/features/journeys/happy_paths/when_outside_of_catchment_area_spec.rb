require "rails_helper"

RSpec.feature "Happy journeys", :no_js, :with_cohorts, :with_default_schedules, type: :feature do
  include Helpers::JourneyAssertionHelper
  include Helpers::JourneyStepHelper
  include ApplicationHelper

  include_context "with stubbed Teacher Auth OmniAuth responses"
  include_context "with stubbed Teaching Record System person API"

  work_settings = [
    ["Early years or childcare"],
    ["A school", "Primary school (5 to 11)"],
    ["Another setting"],
    ["Other"],
  ]

  work_settings.each do |work_setting|
    let(:work_setting) { work_setting }

    scenario "registration journey when outside of catchment area working in #{work_setting.last}" do
      navigate_to_page(path: "/", submit_form: false) do
        page.click_button("Start now")
      end

      choose_course_start_date

      expect_page_to_have(path: "/registration/check-funding", submit_form: true) do
        click_button("Check funding")
      end

      expect_page_to_have(path: "/registration/teacher-catchment", submit_form: true) do
        choose("No", visible: :all)
      end

      expect_page_to_have(path: "/registration/ineligible-for-funding", submit_form: true, submit_button_text: "Continue to register") do
        expect(page).to have_text("DfE scholarship funding")
        expect(page).to have_text("You’re not eligible for DfE scholarship funding because you do not work in England.")
      end

      expect_page_to_have(path: "/registration/choose-your-npq", submit_form: true) do
        page.choose("Senior leadership", visible: :all)
      end

      expect_page_to_have(path: "/registration/work-setting", submit_form: true) do
        page.choose(work_setting.first, visible: :all)
        page.choose(work_setting.second, visible: :all) if work_setting.second
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

      expect_page_to_have(path: "/registration/check-answers", submit_form: false) do
        expect_check_answers_page_to_have_answers(
          {
            "DfE scholarship funding" => "Not eligible",
            "Cohort" => course_start_cohort_description,
            "Course" => "Senior leadership",
            "Course funding" => "I am paying",
            "Work setting" => work_setting.last,
            "Provider" => "Teach First",
            "Working in England" => "No",
          },
        )
        expect(page).to have_content 'funding_eligiblity_status_code: "not_in_england"'
      end

      check_back_journey_is_correct(exclude_current_page: true)
    end
  end
end
