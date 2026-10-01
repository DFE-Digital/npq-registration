require "rails_helper"

RSpec.feature "Sad journeys", :with_cohorts, :with_default_schedules, type: :feature do
  include Helpers::JourneyAssertionHelper
  include Helpers::JourneyStepHelper

  include_context "with stubbed Teacher Auth OmniAuth responses"
  include_context "with stubbed Teaching Record System person API"

  before do
    # create a school in Wales
    School.create!(urn: 100_099, name: "open wrexham school", address_1: "street 4", town: "wrexham", establishment_status_code: "1", establishment_type_code: "30")
  end

  context "with JS", :js do
    scenario("childcare provider not in England") { run_scenario(js: true) }
  end

  context "without JS", :no_js do
    scenario("childcare provider not in England") { run_scenario(js: false) }
  end

  def run_scenario(js:)
    complete_journey_as_far_as_choosing_a_work_setting(
      course: "Headship",
      work_setting: "Early years or childcare",
    )

    expect_page_to_have(path: "/registration/kind-of-nursery", submit_form: true) do
      page.choose("Local authority-maintained nursery", visible: :all)
    end

    choose_a_childcare_provider(js:, name: "open")

    expect_page_to_have(path: "/registration/childcare-provider-not-in-england", submit_form: false) do
      expect(page).to have_text("Nursery must be in England, Guernsey, Jersey or the Isle of Man")
      expect(page).to have_text("This NPQ application can only be completed by people working in these locations.")
      expect(page).not_to have_button("Continue")
    end

    check_back_journey_is_correct(exclude_current_page: true)

    page.click_link("Back")

    expect_page_to_have(path: "/registration/work-setting", submit_form: false)
  end
end
