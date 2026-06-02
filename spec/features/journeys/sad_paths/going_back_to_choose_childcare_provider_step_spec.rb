require "rails_helper"

RSpec.feature "Sad journeys", :with_cohorts, :with_default_schedules, :with_default_school, type: :feature do
  include Helpers::JourneyAssertionHelper
  include Helpers::JourneyStepHelper
  include ApplicationHelper

  include_context "with stubbed Teacher Auth OmniAuth responses"
  include_context "with stubbed Teaching Record System person API"

  let(:school_name) { "open" }

  context "when JavaScript is enabled", :js do
    scenario("going back to the choose childcare provider step") { run_scenario(js: true) }
  end

  context "when JavaScript is disabled", :no_js do
    scenario("going back to the choose childcare provider step") { run_scenario(js: false) }
  end

  def run_scenario(js:)
    # first, get past the choose childcare provider step

    stub_participant_validation_request

    navigate_to_page(path: "/", submit_form: false, axe_check: false) do
      page.click_button("Start now")
    end

    choose_course_start_date

    navigate_to_page(path: "/registration/provider-check", submit_form: true) do
      page.choose("Yes", visible: :all)
    end

    navigate_to_page(path: "/registration/teacher-catchment", axe_check: false, submit_form: true) do
      page.choose("Yes", visible: :all)
    end

    navigate_to_page(path: "/registration/work-setting", submit_form: true) do
      page.choose("Early years or childcare", visible: :all)
    end

    navigate_to_page(path: "/registration/kind-of-nursery", submit_form: true) do
      page.choose("Local authority-maintained nursery", visible: :all)
    end

    choose_a_childcare_provider(js:, name: school_name)

    expect_page_to_have(path: "/registration/choose-your-npq", submit_form: false)

    # go back to the choose childcare provider step

    click_link "Back"
    expect_childcare_provider_picker_to_have_selected(js:, nursery: default_school)

    # go to the check your answers page and then back to the choose childcare provider step

    click_button "Continue"

    expect_page_to_have(path: "/registration/choose-your-npq", submit_form: true) do
      page.choose("Early years leadership", visible: :all)
    end

    navigate_to_page(path: "/registration/possible-funding", submit_form: false) do
      page.click_button("Continue")
    end

    navigate_to_page(path: "/registration/choose-your-provider", submit_form: true) do
      page.choose("Teach First", visible: :all)
    end

    navigate_to_page(path: "/registration/share-provider", submit_form: true) do
      page.check("Yes, I agree to share my information", visible: :all)
    end

    expect_page_to_have(path: "/registration/check-answers", submit_form: false) do
      page.click_link("Change", href: "/registration/choose-childcare-provider/change")
    end

    expect_childcare_provider_picker_to_have_selected(js:, nursery: default_school)
  end
end
