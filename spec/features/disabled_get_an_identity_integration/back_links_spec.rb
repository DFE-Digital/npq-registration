require "rails_helper"

RSpec.feature "Back links", type: :feature do
  include_context "Disable Get An Identity integration"

  scenario "back to previous page retains state" do
    visit "/"
    page.click_link("Start now")

    expect(page).to be_axe_clean
    expect(page).to have_text("Have you already chosen an NPQ and provider?")
    page.choose("Yes", visible: :all)
    page.click_button("Continue")

    page.click_link("Back")

    expect(page).to be_axe_clean
    expect(page).to have_checked_field("Yes", visible: :all)
  end
end
