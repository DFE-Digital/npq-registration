require "rails_helper"

RSpec.feature "Sessions", type: :feature do
  include_context "Enable Get An Identity integration"

  scenario "signing in when user does not exist" do
    visit "/sign-in"
    expect(page).to be_axe_clean
    expect(page).to have_content("Sign in")
    page.fill_in "What’s your email address?", with: "user@example.com"
    page.click_button "Sign in"

    expect(page).to be_axe_clean
    expect(page).to have_content("Check your email")
    expect(ActionMailer::Base.deliveries.size).to be_zero
  end

  scenario "signing in when user exists" do
    User.create!(email: "user@example.com")

    visit "/sign-in"
    expect(page).to have_content("Sign in")
    page.fill_in "What’s your email address?", with: " User@example.com "
    page.click_button "Sign in"

    code = ActionMailer::Base.deliveries.last[:personalisation].unparsed_value[:code]

    expect(page).to have_content("Check your email")
    page.fill_in "Enter your code", with: code
    page.click_button "Sign in"

    expect(page).to be_axe_clean
    expect(page).to have_content("NPQ applications")
    expect(page).not_to have_content("Admin")

    visit "/admin"
    expect(page.current_path).to eql("/sign-in")
  end
end
