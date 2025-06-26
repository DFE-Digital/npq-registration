require "rails_helper"

RSpec.feature "Sad journey", :with_default_schedules, type: :feature do
  include Helpers::JourneyAssertionHelper
  include ApplicationHelper

  include_context "with default schedules"
  include_context "Stub Get An Identity Omniauth Responses"

  context "when JavaScript is disabled", :no_js do
    scenario("when going back and changing referred by return to teaching adviser") { run_scenario }
  end

  def run_scenario
    stub_participant_validation_request

    navigate_to_page(path: "/", submit_form: false, axe_check: false) do
      page.click_button("Start now")
    end

    expect_page_to_have(path: "/registration/course-start-date", submit_form: true) do
      page.choose("Yes", visible: :all)
    end

    expect_page_to_have(path: "/registration/provider-check", submit_form: true) do
      page.choose("Yes", visible: :all)
    end

    expect_page_to_have(path: "/registration/teacher-catchment", axe_check: false, submit_form: true) do
      page.choose("Yes", visible: :all)
    end

    expect_page_to_have(path: "/registration/work-setting", submit_form: true) do
      page.choose("Other", visible: :all)
    end

    expect_page_to_have(path: "/registration/referred-by-return-to-teaching-adviser", submit_form: true) do
      page.choose("No", visible: :all)
    end

    expect_page_to_have(path: "/registration/choose-your-npq", submit_form: true) do
      page.choose("Senior leadership", visible: :all)
    end

    expect_page_to_have(path: "/registration/ineligible-for-funding", submit_form: false)

    click_link "Back"
    click_link "Back"
    click_button "Continue"

    expect_page_to_have(path: "/registration/referred-by-return-to-teaching-adviser", submit_form: true) do
      page.choose("Yes", visible: :all)
    end

    click_button "Continue"
    click_button "Continue"

    click_link "Back"
    click_link "Back"

    expect_page_to_have(path: "/registration/course-start-date")
  end
end
