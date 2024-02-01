require "rails_helper"

RSpec.feature "Sad journeys", type: :feature do
  include Helpers::JourneyAssertionHelper
  include Helpers::JourneyStepHelper

  include_context "retrieve latest application data"
  include_context "Stub Get An Identity Omniauth Responses"

  context "when JavaScript is enabled", :js do
    scenario("Not chosen DQT or provider (with JS)") { run_scenario(js: true) }
  end

  context "when JavaScript is disabled", :no_js do
    scenario("Not chosen DQT or provider (without JS)") { run_scenario(js: false) }
  end

  def run_scenario(*)
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
      page.choose("No", visible: :all)
    end

    expect(page).to have_text("Choose an NPQ and provider")

    expect(retrieve_latest_application_user_data).to match(nil)
    expect(retrieve_latest_application_data).to match(nil)
  end
end
