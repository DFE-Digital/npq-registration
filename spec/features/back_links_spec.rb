require "rails_helper"

RSpec.feature "Back links", type: :feature do
  scenario "back to previous page retains state" do
    visit "/"
    page.click_link("Start now")

    # expect(page).to be_axe_clean
    # TODO: aria-expanded
    expect(page.current_path).to eql("/registration/teacher-catchment")
    page.choose("England", visible: :all)
    page.click_button("Continue")

    expect(page).to be_axe_clean
    expect(page).to have_text("Have you already chosen an NPQ and provider?")
    page.choose("Yes, I have chosen my NPQ and provider", visible: :all)
    page.click_button("Continue")

    expect(page).to be_axe_clean
    page.click_link("Back")

    expect(page).to be_axe_clean
    expect(page).to have_checked_field("Yes, I have chosen my NPQ and provider", visible: :all)
  end
end
