require "rails_helper"

RSpec.feature "Back links", type: :feature do
  scenario "back to previous page retains state" do
    visit "/"
    page.click_link("Start now")

    expect(page).to have_text("Have you already chosen an NPQ and provider?")
    page.choose("Yes, I have chosen my NPQ and provider")
    page.click_button("Continue")

    page.check("Yes, I agree my information can be shared")
    page.click_button("Continue")

    page.click_link("Back")
    expect(page).to have_checked_field("Yes, I agree my information can be shared")
  end
end
