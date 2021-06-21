require "rails_helper"

RSpec.feature "Privacy Policy", type: :feature do
  scenario "view info about privacy policy" do
    visit "/"
    click_link("Privacy")
    expect(page).to have_content("Who we are and why we process personal data")
  end
end
