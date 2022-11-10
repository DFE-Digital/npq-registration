require "rails_helper"

RSpec.feature "Register interest", type: :feature do
  include_context "Enable Get An Identity integration"

  scenario "Sign up to notification with direct link" do
    visit "/registration-interest/sign-up"

    expect(page).to be_axe_clean
    expect(page).to have_text("What’s your email address")
    page.fill_in "What’s your email address", with: "user@example.com"
    page.click_button("Confirm")

    expect(page).to be_axe_clean
    expect(page.current_path).to eq("/registration-interest/sign-up/confirm")
    expect(page).to have_text("We’ll send an email to user@example.com when registration reopens.")

    expect(RegistrationInterest.count).to eql(1)
  end
end
