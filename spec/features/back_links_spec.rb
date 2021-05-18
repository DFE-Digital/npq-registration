require "rails_helper"

RSpec.feature "Back links", type: :feature do
  scenario "back to previous page retains state" do
    visit "/"
    page.click_link("Start now")

    page.check("I agree my choices can be shared with my training provider")
    page.click_button("Continue")

    page.click_link("Back")
    expect(page).to have_checked_field("I agree my choices can be shared with my training provider")
  end
end
