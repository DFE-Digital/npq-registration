require "rails_helper"

RSpec.feature "Sessions", type: :feature do
  scenario "signing in when user does not exist" do
    visit "/sign-in"
    expect(page).to have_content("Sign in")
    page.fill_in "Email address", with: "user@example.com"
    page.click_button "Sign in"

    expect(page).to have_content("Check your email")

    expect(ActionMailer::Base.deliveries.size).to be_zero
  end

  scenario "signing in when user exists" do
    User.create!(email: "user@example.com")

    visit "/sign-in"
    expect(page).to have_content("Sign in")
    page.fill_in "Email address", with: "user@example.com"
    page.click_button "Sign in"

    code = ActionMailer::Base.deliveries.last[:personalisation].unparsed_value[:code]

    expect(page).to have_content("Check your email")
    page.fill_in "Enter your code", with: code
    page.click_button "Sign in"

    expect(page).to have_content("NPQ applications")
  end
end
