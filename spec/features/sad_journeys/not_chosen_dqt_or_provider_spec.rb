require "rails_helper"

RSpec.feature "Happy journeys", type: :feature do
  include Helpers::JourneyHelper
  include Helpers::JourneyAssertionHelper

  include_context "retrieve latest application data"
  include_context "Stub Get An Identity Omniauth Responses"

  scenario "Not chosen DQT or provider" do
    stub_participant_validation_request

    navigate_to_page(path: "/", submit_form: false, axe_check: false) do
      expect(page).to have_text("Before you start")
      page.click_button("Start now")
    end

    expect(page).not_to have_content("Before you start")

    expect_page_to_have(path: "/registration/provider-check", submit_form: true) do
      expect(page).to have_text("Have you already chosen an NPQ and provider?")
      page.choose("No", visible: :all)
    end

    expect(page).to be_axe_clean
    expect(page).to have_text("Choose an NPQ and provider")

    expect(retrieve_latest_application_user_data).to match(nil)
    expect(retrieve_latest_application_data).to match(nil)
  end
end
