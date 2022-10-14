require "rails_helper"

RSpec.feature "Accessibility Statement", type: :feature do
  scenario "View info about accessibility statement" do
    visit "/"
    click_link("Accessibility")

    expect(page).to be_axe_clean
    expect(page).to have_content("Accessibility statement for Register for a national professional qualification service")
  end
end
