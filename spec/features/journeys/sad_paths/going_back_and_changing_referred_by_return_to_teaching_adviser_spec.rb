require "rails_helper"

RSpec.feature "Sad journey", :no_js, :with_cohorts, :with_default_schedules, type: :feature do
  include Helpers::JourneyAssertionHelper
  include Helpers::JourneyStepHelper
  include ApplicationHelper

  include_context "with stubbed Teacher Auth OmniAuth responses"
  include_context "with stubbed Teaching Record System person API"

  scenario "when going back and changing referred by return to teaching adviser" do
    complete_journey_as_far_as_choosing_a_work_setting(
      course: "Senior leadership",
      work_setting: "Other",
    )

    expect_page_to_have(path: "/registration/referred-by-return-to-teaching-adviser", submit_form: true) do
      page.choose("No", visible: :all)
    end

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

    expect_check_answers_page_to_have_answers(
      {
        "Course funding" => "I am paying",
        "Cohort" => "Autumn 2026",
        "Course" => "Senior leadership",
        "DfE scholarship funding" => "Not eligible",
        "Provider" => "Teach First",
        "Referred by return to teaching adviser" => "No",
        "Work setting" => "Other",
        "Working in England" => "Yes",
      },
    )

    # now go back to the RTTA question, and change the answer

    click_link "Back"
    expect_page_to_have(path: "/registration/share-provider", submit_form: false) do
      click_link "Back"
    end
    expect_page_to_have(path: "/registration/choose-your-provider", submit_form: false) do
      click_link "Back"
    end
    expect_page_to_have(path: "/registration/funding-your-npq", submit_form: false) do
      click_link "Back"
    end
    expect_page_to_have(path: "/registration/ineligible-for-funding", submit_form: false) do
      click_link "Back"
    end
    expect_page_to_have(path: "/registration/work-setting", submit_form: false) do
      click_button "Continue"
    end

    expect_page_to_have(path: "/registration/referred-by-return-to-teaching-adviser", submit_form: true) do
      page.choose("Yes", visible: :all)
    end

    expect_page_to_have(path: "/registration/possible-funding", submit_form: true)
    expect_page_to_have(path: "/registration/choose-your-provider", submit_form: true)
    expect_page_to_have(path: "/registration/share-provider", submit_form: true)

    expect_check_answers_page_to_have_answers(
      {
        "Cohort" => "Autumn 2026",
        "Course" => "Senior leadership",
        "DfE scholarship funding" => "Not eligible",
        "Provider" => "Teach First",
        "Referred by return to teaching adviser" => "Yes",
        "Work setting" => "Other",
        "Working in England" => "Yes",
      },
    )
  end
end
