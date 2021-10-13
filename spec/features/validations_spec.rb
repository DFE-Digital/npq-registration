require "rails_helper"

RSpec.feature "Validations", type: :feature do
  scenario "did not agree to share data with provider" do
    visit "/"

    page.click_link("Start now")
    page.click_button("Continue")

    expect(page).to be_axe_clean
    expect(page).to have_text("Choose whether")
  end
end
