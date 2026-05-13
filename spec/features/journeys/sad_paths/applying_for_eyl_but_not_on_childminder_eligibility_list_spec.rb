require "rails_helper"

RSpec.feature "Happy journeys", :no_js, :with_default_schedules, :with_eligibility_list_entries, type: :feature do
  include Helpers::JourneyAssertionHelper
  include Helpers::JourneyStepHelper
  include ApplicationHelper

  # include_context "retrieve latest application data"
  include_context "Stub Get An Identity Omniauth Responses"

  scenario "registration journey while working at a childminder but not on the childminder eligibility list" do
    stub_participant_validation_request

    navigate_to_page(path: "/", submit_form: false, axe_check: false) do
      expect(page).to have_text("Before you start")
      page.click_button("Start now")
    end

    expect(page).not_to have_content("Before you start")

    choose_course_start_date

    expect_page_to_have(path: "/registration/provider-check", submit_form: true) do
      expect(page).to have_text("Have you chosen an NPQ and provider?")
      page.choose("Yes", visible: :all)
    end

    # TODO: aria-expanded
    expect_page_to_have(path: "/registration/teacher-catchment", axe_check: false, submit_form: true) do
      page.choose("Yes", visible: :all)
    end

    expect_page_to_have(path: "/registration/work-setting", submit_form: true) do
      page.choose("Early years or childcare", visible: :all)
    end

    expect_page_to_have(path: "/registration/kind-of-nursery", submit_form: true) do
      page.choose("As a childminder", visible: :all)
    end

    expect_page_to_have(path: "/registration/have-ofsted-urn", submit_form: true) do
      page.choose("Yes", visible: :all)
    end

    choose_a_private_childcare_provider(js: false, urn: "EY487263", name: "searchable childcare provider")

    expect_page_to_have(path: "/registration/choose-your-npq", submit_form: true) do
      page.choose("Early years leadership", visible: :all)
    end

    expect_page_to_have(path: "/registration/ineligible-for-funding", submit_form: false) do
      expect(page).to have_text("You’re not eligible for scholarship funding for the Early years leadership NPQ")
      expect(page).to have_text("as your workplace is not in the list of EY settings that are eligible for funding")
      page.click_on("Continue")
    end

    expect_page_to_have(path: "/registration/funding-your-npq", submit_form: true) do
      page.choose("I am paying", visible: :all)
    end

    expect_page_to_have(path: "/registration/choose-your-provider", submit_form: true) do
      expect(page).to have_text("Select your provider")
      page.choose("Teach First", visible: :all)
    end

    expect_page_to_have(path: "/registration/share-provider", submit_form: true) do
      expect(page).to have_text("Sharing your NPQ information")
      page.check("Yes, I agree to share my information", visible: :all)
    end

    expect_page_to_have(path: "/registration/check-answers", submit_button_text: "Submit", submit_form: true) do
      expect_check_answers_page_to_have_answers(
        {
          "Course funding" => "I am paying",
          "Course start" => course_start_cohort_description,
          "Course" => "Early years leadership",
          "Early years setting" => "As a childminder",
          "Ofsted unique reference number (URN)" => "EY487263 – searchable childcare provider – street 1, manchester",
          "Provider" => "Teach First",
          "Work setting" => "Early years or childcare",
          "Workplace in England" => "Yes",
        },
      )
    end

    expect_applicant_reached_end_of_journey
  end
end
