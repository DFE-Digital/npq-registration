require "rails_helper"

RSpec.feature "Happy journeys", :no_js, :with_cohorts, :with_default_schedules, :with_default_school, type: :feature do
  include Helpers::JourneyAssertionHelper
  include Helpers::JourneyStepHelper
  include ApplicationHelper

  include_context "Stub Get An Identity Omniauth Responses"

  before do
    # create course cohort providers for the unfunded spring 2026a cohort
    file_name = "db/seeds/data/unfunded_spring_2026a_course_cohort_providers.csv"
    CourseCohortProviders::Updater.new(cohort: Cohort.find_by(identifier: "2026a"), course_to_provider_csv: file_name, dry_run: false).call
  end

  scenario "unfunded cohort registration journey" do
    stub_participant_validation_request

    navigate_to_page(path: "/", submit_form: false, axe_check: false) do
      page.click_button("Start now")
    end

    expect_page_to_have(path: "/registration/course-start-date", submit_form: true) do
      page.choose("Spring 2026", visible: :all)
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

    choose_a_school(js: false, name: "open")

    expect_page_to_have(path: "/registration/choose-your-npq", submit_form: true) do
      page.choose("Headship", visible: :all)
    end

    expect_page_to_have(path: "/registration/ineligible-for-funding", submit_form: false) do
      expect(page).to have_content("You’re not eligible for scholarship funding for the Headship NPQ course as you have selected the Spring 2026 cohort.")
      page.click_link("Continue")
    end

    expect_page_to_have(path: "/registration/funding-your-npq", submit_form: true) do
      page.choose "My trust is paying", visible: :all
    end

    expect_page_to_have(path: "/registration/choose-your-provider", submit_form: true) do
      page.choose("Ambition Institute", visible: :all)
    end

    expect_page_to_have(path: "/registration/share-provider", submit_form: true) do
      page.check("Yes, I agree to share my information", visible: :all)
    end

    expect_page_to_have(path: "/registration/check-answers", submit_button_text: "Submit", submit_form: true) do
      expect_check_answers_page_to_have_answers(
        {
          "Course start" => "Spring 2026",
          "Course" => "Headship",
          "Provider" => "Ambition Institute",
          "Workplace" => "open manchester school – street 1, manchester",
          "Course funding" => "My trust is paying",
          "Work setting" => "A school",
          "Workplace in England" => "Yes",
        },
      )
    end

    expect_applicant_reached_end_of_journey

    application = Application.last
    expect(application.funded_place).to be(false)
    expect(application.eligible_for_funding).to be(false)
    expect(application.cohort.funding).to eq "zero"
  end
end
