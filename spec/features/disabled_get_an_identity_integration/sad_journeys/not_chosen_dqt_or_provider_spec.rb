require "rails_helper"

RSpec.feature "Happy journeys", type: :feature do
  include Helpers::JourneyHelper

  include Helpers::JourneyAssertionHelper

  include_context "retrieve latest application data"
  include_context "Disable Get An Identity integration"

  scenario "Not chosen DQT or provider" do
    visit "/"
    expect(page).to have_text("Before you start")
    page.click_link("Start now")

    expect(page).to be_axe_clean
    expect(page).to have_text("Have you already chosen an NPQ and provider?")
    page.choose("No", visible: :all)
    page.click_button("Continue")

    expect(page).to be_axe_clean
    expect(page).to have_text("Choose an NPQ and provider")

    expect(retrieve_latest_application_user_data).to match(nil)
    expect(retrieve_latest_application_data).to match(nil)
  end
end
