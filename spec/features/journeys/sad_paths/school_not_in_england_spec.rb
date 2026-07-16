require "rails_helper"

RSpec.feature "Sad journeys", :with_cohorts, :with_default_schedules, type: :feature do
  include Helpers::JourneyAssertionHelper
  include Helpers::JourneyStepHelper

  include_context "retrieve latest application data"
  include_context "with stubbed Teacher Auth OmniAuth responses"
  include_context "with stubbed Teaching Record System person API"

  before do
    # create a school in Wales
    School.create!(urn: 100_099, name: "open wrexham school", address_1: "street 4", town: "wrexham", establishment_status_code: "1", establishment_type_code: "30")
  end

  context "when JavaScript is enabled", :js do
    scenario("school not in England (with JS)") { run_scenario(js: true) }
  end

  context "when JavaScript is disabled", :no_js do
    scenario("school not in England (without JS)") { run_scenario(js: false) }
  end

  def run_scenario(js:)
    stub_participant_validation_request

    complete_journey_as_far_as_choosing_a_work_setting(
      course: "Headship",
      work_setting: "A school",
    )

    choose_a_school(js:, name: "open wrexham school")

    expect_page_to_have(path: "/registration/school-not-in-england", submit_form: false) do
      expect(page).to have_text("School or college must be in England")

      page.click_link("Back")
    end

    expect_page_to_have(path: "/registration/choose-school", submit_form: false) do
      expected_text = js ? "What is the name of your workplace?" : "Select your workplace"
      expect(page).to have_text(expected_text)
    end

    expect(retrieve_latest_application_user_data).to match(nil)
    expect(retrieve_latest_application_data).to match(nil)
  end
end
