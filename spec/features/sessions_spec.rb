require "rails_helper"

RSpec.feature "Sessions", type: :feature do
  include_context "Stub Get An Identity Omniauth Responses"

  scenario "signing in when user does not exist" do
    visit "/sign-in"
    expect(page).to be_accessible
    expect(page).to have_content("Sign in")
    page.fill_in "What’s your email address?", with: "user@example.com"
    page.click_button "Sign in"

    expect(page).to be_accessible
    expect(page).to have_content("Check your email")
    expect(ActionMailer::Base.deliveries.size).to be_zero
  end

  scenario "signing in when admin exists" do
    FactoryBot.create(:admin, email: "user@example.com")

    visit "/sign-in"
    expect(page).to have_content("Sign in")
    page.fill_in "What’s your email address?", with: " User@example.com "
    page.click_button "Sign in"

    expect(page).to have_content("Check your email")

    code = ActionMailer::Base.deliveries.last.personalisation[:code]
    page.fill_in "Enter your code", with: code
    page.click_button "Sign in"

    expect(page).to have_content("Register for a national professional qualification")
    expect(page).to have_content("Admin")
  end
end
