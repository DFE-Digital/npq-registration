require "rails_helper"

RSpec.feature "Sessions", type: :feature do
  let(:stubbed_url) { "https://example.com" }
  let(:stubbed_client_id) { "register-for-npq" }
  let(:stubbed_redirect_uri) { "https://example.com/" }

  include_context "Stub Get An Identity Omniauth Responses"

  scenario "signing in when user does not exist" do
    stub_const("ENV", ENV.to_hash.merge("TRA_OIDC_DOMAIN" => stubbed_url))
    stub_const("ENV", ENV.to_hash.merge("TRA_OIDC_CLIENT_ID" => stubbed_client_id))
    stub_const("ENV", ENV.to_hash.merge("TRA_OIDC_REDIRECT_URI" => stubbed_redirect_uri))

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
    stub_const("ENV", ENV.to_hash.merge("TRA_OIDC_DOMAIN" => stubbed_url))
    stub_const("ENV", ENV.to_hash.merge("TRA_OIDC_CLIENT_ID" => stubbed_client_id))
    stub_const("ENV", ENV.to_hash.merge("TRA_OIDC_REDIRECT_URI" => stubbed_redirect_uri))
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
    expect(page).to have_content("Your NPQ registration")
    expect(page).not_to have_content("Admin")

    visit "/admin"
    expect(page).to have_current_path("/sign-in")
  end
end
