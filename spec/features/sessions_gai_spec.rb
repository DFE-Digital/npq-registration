require "rails_helper"

RSpec.feature "Sessions: integration with GAI", type: :feature do
  include Helpers::JourneyHelper

  include_context "Stub Get An Identity Omniauth Responses"

  # this is puzzling, we're testing GAI but logging in with a OTP
  xscenario "GAI header links are only visible for logged-in users" do
    User.create!(email: "user@example.com")

    visit "/sign-in"
    expect(page).not_to have_content("Sign out")
    expect(page).not_to have_content("DfE Identity Account")

    page.fill_in "What’s your email address?", with: " User@example.com "
    page.click_button "Sign in"

    code = ActionMailer::Base.deliveries.last[:personalisation].unparsed_value[:code]

    expect(page).to have_content("Check your email")
    page.fill_in "Enter your code", with: code
    page.click_button "Sign in"

    expect(page).to have_link("Sign out", href: /\/sign-out/)
    expect(page).to have_link("DfE Identity account", href: /\/account\?client_id=register-for-npq&redirect_uri=[^&]+&sign_out_uri=[^&]+/)
  end
end
