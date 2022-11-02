require "rails_helper"

RSpec.feature "Validations", type: :feature do
  scenario "did not agree to share data with provider" do
    visit "/"

    page.click_link("Start now")
    page.click_button("Continue")

    expect(page).to have_text("Select whether")
  end
end
