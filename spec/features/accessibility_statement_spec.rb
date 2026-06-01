require "rails_helper"

RSpec.feature "Accessibility Statement", type: :feature do
  include_context "with stubbed Teacher Auth OmniAuth responses"

  scenario "View info about accessibility statement" do
    visit "/"
    click_link("Accessibility")

    expect(page).to be_accessible
    expect(page).to have_content("Accessibility statement")
  end
end
