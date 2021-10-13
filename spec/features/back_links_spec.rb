require "rails_helper"

RSpec.feature "Back links", type: :feature do
  scenario "back to previous page retains state" do
    visit "/"
    page.click_link("Start now")

    expect(page).to be_axe_clean
    expect(page).to have_text("Are you a teacher in England, Jersey, Guernsey or the Isle of Man?")
    page.choose("Yes", visible: :all)
    page.click_button("Continue")

    expect(page).to be_axe_clean
    expect(page).to have_text("Have you already chosen an NPQ and provider?")
    page.choose("Yes, I have chosen my NPQ and provider", visible: :all)
    page.click_button("Continue")

    expect(page).to be_axe_clean
    page.check("Yes, I agree my information can be shared", visible: :all)
    page.click_button("Continue")

    expect(page).to be_axe_clean
    page.click_link("Back")

    expect(page).to be_axe_clean
    expect(page).to have_checked_field("Yes, I agree my information can be shared", visible: :all)
  end
end
