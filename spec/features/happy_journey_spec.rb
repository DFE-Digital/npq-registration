require "rails_helper"

RSpec.feature "Happy journey", type: :feature do
  scenario "complete entire journey via happy path" do
    visit "/"
    expect(page).to have_text("Before you start")

    page.click_link("Start now")
    expect(page).to have_text("Share choices with training provider")
  end
end
