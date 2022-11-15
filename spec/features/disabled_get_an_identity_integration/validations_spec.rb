require "rails_helper"

RSpec.feature "Validations", type: :feature do
  include_context "Disable Get An Identity integration"

  scenario "did not agree to share data with provider" do
    visit "/"

    page.click_link("Start now")
    page.click_button("Continue")

    expect(page).to have_text("Select whether")
  end
end
