require "rails_helper"

# To update the id_token fixtures using real responses:
# you will need to have 2 user accounts, onw with a TRN and one without
# 1. remove the old fixtures from spec/fixtures/omniauth_hashes/
# 2. in .env.test:
#   comment out HOSTING_DOMAIN
#   comment out the existing TRA_OIDC_* env vars, and copy the 5 TRA_OIDC_* env vars from .env
# 3. set `regenerate_fixtures` to true below
# 4. update `email_for_account_with_trn` to the email address for the account with a TRN
# 5. update `email_for_account_without_trn` to the email address for the account without a TRN
# 6. make sure your local server is not running on port 3000
# 7. run the first 2 specs - be sure to follow the prompts from the command-line, and do not enter your code into the browser
RSpec.feature "DfE Sign In", :with_default_schedules, type: :feature do
  include Helpers::JourneyAssertionHelper
  include Helpers::JourneyStepHelper

  before do
    WebMock.disable_net_connect!(allow_localhost: true, allow: URI(ENV["TRA_OIDC_DOMAIN"]).host)
  end

  regenerate_fixtures = false # set to true to regenerate fixtures

  let(:fixtures_path) { Rails.root.join("spec/fixtures/omniauth_hashes").freeze }

  let(:email_for_account_with_trn) { "user@example.com" }
  let(:email_for_account_without_trn) { "user+notrn@example.com" }

  def strip_pii(omniauth_hash)
    omniauth_hash.tap do |hash|
      hash["uid"] = SecureRandom.uuid
      hash["info"]["name"] = "John Doe"
      hash["info"]["email"] = "user@example.com"
      hash["info"]["last_name"] = "Doe"
      hash["info"]["first_name"] = "John"
      hash["extra"]["raw_info"]["name"] = "John Doe"
      hash["extra"]["raw_info"]["email"] = "user@example.com"
      hash["extra"]["raw_info"]["given_name"] = "John"
      hash["extra"]["raw_info"]["family_name"] = "Doe"
      hash["extra"]["raw_info"]["preferred_name"] = "John Doe"
      hash["credentials"]["token"] = "sometoken"
      hash["credentials"]["id_token"] = "someidtoken"
    end
  end

  def login_with_email(email)
    navigate_to_page(path: "/", submit_form: false, axe_check: false) do
      click_button("Start now")
    end

    click_link "Sign in"
    fill_in "Your email address", with: email

    click_button "Continue"
    puts "Enter code from email:"
    code = $stdin.gets.chomp

    fill_in "Enter your code", with: code
    click_button "Continue"
    click_button "Continue"

    url = URI(page.driver.browser.network.request.to_h["request"]["url"])
    visit "#{url.path}?#{url.query}"
  end

  scenario "capture omniauth authentication hash for user with TRN", skip: !regenerate_fixtures do
    login_with_email(email_for_account_with_trn)

    expect(page).to have_current_path "/registration/course-start-date"
    File.open(fixtures_path.join("tra_openid_connect_auth_with_trn.json"), "w") do |file|
      file.write strip_pii(User.last.raw_tra_provider_data).to_json
    end
  end

  scenario "capture omniauth authentication hash for user without TRN", skip: !regenerate_fixtures do
    login_with_email(email_for_account_without_trn)

    expect(page).to have_current_path "/registration/teacher-reference-number"
    File.open(fixtures_path.join("tra_openid_connect_auth_no_trn.json"), "w") do |file|
      file.write strip_pii(User.last.raw_tra_provider_data).to_json
    end
  end

  scenario "DfE Sign In using captured omniauth hash for a user with a TRN" do
    stubbed_callback_response = JSON.load_file(fixtures_path.join("tra_openid_connect_auth_with_trn.json"))
    OmniAuth.config.test_mode = true
    OmniAuth.config.add_mock(:tra_openid_connect, stubbed_callback_response)

    navigate_to_page(path: "/", submit_form: false, axe_check: false) do
      click_button("Start now")
    end

    expect(page).to have_current_path "/registration/course-start-date"
    expect(User.last.trn).not_to be_blank
  end

  scenario "DfE Sign In using captured omniauth hash for a user with no TRN" do
    stubbed_callback_response = JSON.load_file(fixtures_path.join("tra_openid_connect_auth_no_trn.json"))
    OmniAuth.config.test_mode = true
    OmniAuth.config.add_mock(:tra_openid_connect, stubbed_callback_response)

    navigate_to_page(path: "/", submit_form: false, axe_check: false) do
      click_button("Start now")
    end

    expect(page).to have_current_path "/registration/teacher-reference-number"
    expect(User.last.trn).to be_blank
  end
end
