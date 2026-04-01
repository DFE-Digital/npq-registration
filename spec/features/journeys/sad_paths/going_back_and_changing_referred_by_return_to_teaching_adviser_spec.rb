require "rails_helper"

# This is the exact scenario from bug CPDNPQ-2812.
# The main issue is the steps when clicking 'Back' are completely wrong.
# The fix put in was just a quick fix - making the back steps correct will also fix the issue, but it's a larger piece of work (see CPDNPQ-3053).
RSpec.feature "Sad journey", :with_default_schedules, type: :feature do
  include Helpers::JourneyAssertionHelper
  include ApplicationHelper

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
    expect(page).to have_current_path("/registration/choose-your-npq")

    click_link "Back"

    unless Rails.configuration.x.dfe_wizard
      # FIXME: Spec encodes bug in back button behaviour under old wizard model
      click_button "Continue"
    end

    expect_page_to_have(path: "/registration/referred-by-return-to-teaching-adviser", submit_form: true) do
      page.choose("Yes", visible: :all)
    end

    expect(page).to have_current_path("/registration/choose-your-npq")
    click_button "Continue"

    expect(page).to have_current_path("/registration/possible-funding")
    click_button "Continue"

    expect(page).to have_current_path("/registration/choose-your-provider")
    click_link "Back"

    if Rails.configuration.x.dfe_wizard
      expect(page).to have_current_path("/registration/possible-funding")

      click_link "Back"
      expect_page_to_have(path: "/registration/choose-your-npq")
    else
      # FIXME: Spec encodes bug in back button behaviour under old wizard model
      expect(page).to have_current_path("/registration/funding-your-npq")

      click_link "Back"
      expect_page_to_have(path: "/registration/course-start-date")
    end
  end
end
