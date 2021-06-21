require "rails_helper"

RSpec.feature "Accessibility Statement", type: :feature do
  scenario "View info about accessibility statement" do
    visit "/"
    click_link("Accessibility")
    expect(page).to have_content("Accessibility statement for Register for a National Professional Qualification service")
  end
end
