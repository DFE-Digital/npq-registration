require "rails_helper"

RSpec.feature "Previous funded application - when logged in from the start", :no_js, :with_cohorts, :with_default_schedules, type: :feature do
  include Helpers::JourneyAssertionHelper
  include Helpers::JourneyStepHelper
  include ApplicationHelper

  include_context "with stubbed Teacher Auth OmniAuth responses"
  include_context "with stubbed Teaching Record System person API"

  before do
    # create an eligible school
    School.create!(
      urn: 100_000,
      name: "open manchester school",
      address_1: "street 1",
      town: "manchester",
      establishment_status_code: "1",
      establishment_type_code: "1",
    )

    user = create(:user, :with_verified_trn, email: user_email, trn: user_trn)
    create(:application, :accepted, :with_funded_place, user:, course: create(:course, :headship))
  end

  scenario "checks for previous applications" do
    navigate_to_page(path: "/", submit_form: false) do
      page.click_button("Sign in")
    end

    complete_journey_as_far_as_choosing_a_work_setting(
      course: "Headship",
      work_setting: "Primary school (5 to 11)",
    )

    choose_a_school(js: false, name: "open")

    expect_page_to_have(path: "/registration/ineligible-for-funding", submit_form: false) do
      page.click_link "Continue to register"
    end

    expect_page_to_have(path: "/registration/funding-your-npq", submit_form: true) do
      expect(page).to have_text("How are you funding your course?")
      page.choose "I am paying", visible: :all
    end

    expect_page_to_have(path: "/registration/choose-your-provider", submit_form: true) do
      page.choose("Teach First", visible: :all)
    end

    # check_back_journey_is_correct # FIXME: this currently fails

    expect_page_to_have(path: "/registration/share-provider", submit_form: true) do
      page.check("Yes, I agree to share my information", visible: :all)
    end

    expect_page_to_have(path: "/registration/check-answers", submit_form: false) do
      expect_check_answers_page_to_have_answers(
        {
          "Cohort" => "Autumn 2026",
          "Course funding" => "I am paying",
          "Course" => "Headship",
          "DfE scholarship funding" => "Not eligible",
          "Provider" => "Teach First",
          "Work setting" => "Primary school (5 to 11)",
          "Working in England" => "Yes",
          "Workplace" => "open manchester school – street 1, manchester",
        },
      )
    end

    expect(page).not_to have_text("Our records show that you have previously received funding for this course. " \
                                  "This means you are not eligible for further funding.")

    page.click_button "Submit"

    expect_applicant_reached_end_of_journey(total_number_of_created_applications: 2)
  end
end
