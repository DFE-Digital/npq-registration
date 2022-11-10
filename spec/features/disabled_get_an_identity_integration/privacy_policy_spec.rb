require "rails_helper"

RSpec.feature "Privacy Policy", type: :feature do
  include_context "Disable Get An Identity integration"

  scenario "view info about privacy policy" do
    visit "/"
    click_link("Privacy")

    expect(page).to be_axe_clean
    expect(page).to have_content("Who we are and why we process personal data")
  end
end
