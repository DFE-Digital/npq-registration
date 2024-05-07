require "rails_helper"

RSpec.feature "Sad journeys", type: :feature do
  include Helpers::JourneyAssertionHelper
  include Helpers::JourneyStepHelper

  include_context "retrieve latest application data"
  include_context "Stub previously funding check for all courses" do
    let(:api_call_trn) { user_trn }
  end
  include_context "Stub Get An Identity Omniauth Responses"

  context "when JavaScript is enabled", :js do
    scenario("school not in England (with JS)") { run_scenario(js: true) }
  end

  context "when JavaScript is disabled", :no_js do
    scenario("school not in England (without JS)") { run_scenario(js: false) }
  end

  def run_scenario(js:)
    stub_participant_validation_request

    navigate_to_page(path: "/", submit_form: false, axe_check: false) do
      expect(page).to have_text("Before you start")
      page.click_button("Start now")
    end

    expect(page).not_to have_content("Before you start")

    expect_page_to_have(path: "/registration/course-start-date", submit_form: true) do
      expect(page).to have_text("NPQ start dates are usually every February and October.")
      page.choose("Yes", visible: :all)
    end

    expect_page_to_have(path: "/registration/provider-check", submit_form: true) do
      expect(page).to have_text("Have you chosen an NPQ and provider?")
      page.choose("Yes", visible: :all)
    end

    # expect(page).to be_accessible
    # TODO: aria-expanded
    expect_page_to_have(path: "/registration/teacher-catchment", axe_check: false, submit_form: true) do
      page.choose("Yes", visible: :all)
    end

    expect_page_to_have(path: "/registration/work-setting", submit_form: true) do
      page.choose("A school", visible: :all)
    end

    School.create!(urn: 100_099, name: "open wrexham school", address_1: "street 4", town: "wrexham", establishment_status_code: "1", establishment_type_code: "30")
    choose_a_school(js:, location: "wrexham", name: "open wrexham school")

    expect_page_to_have(path: "/registration/school-not-in-england", submit_form: false) do
      expect(page).to have_text("School or college must be in England")

      page.click_link("Back")
    end

    expect_page_to_have(path: "/registration/choose-school", submit_form: false) do
      expected_text = js ? "What’s the name of your workplace?" : "Select your school or 16 to 19 educational setting in wrexham"
      expect(page).to have_text(expected_text)
    end

    expect(retrieve_latest_application_user_data).to match(nil)
    expect(retrieve_latest_application_data).to match(nil)
  end
end
