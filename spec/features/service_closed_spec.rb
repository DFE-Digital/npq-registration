require "rails_helper"

RSpec.feature "Service is closed", type: :feature do
  include Helpers::AdminLogin
  include Helpers::JourneyAssertionHelper
  include Helpers::JourneyStepHelper

  include_context "Stub Get An Identity Omniauth Responses"

  scenario "Service close date has passed" do
    close_registration!

    visit "/"
    expect(page).to have_content("Registration has closed temporarily")
    expect(page).to be_axe_clean

    page.click_button("Request email updates")
    # Due to mocking GAI, we need to manually follow the path
    visit new_email_update_path
    expect(page).to have_content("Request email updates about registration opening")
    expect(page).to be_axe_clean
  end

  scenario "Services closes while registration in progress" do
    open_registration!

    visit "/"
    expect(page).to have_text("Before you start")
    page.click_button("Start now")

    expect(page).to have_text("Course start")
    page.choose("Yes", visible: :all)

    # Registration is now closed
    close_registration!
    page.click_button("Continue")

    expect(page).to have_content("Registration has closed temporarily")
  end

  context "when using late registration" do
    include_context "Stub Get An Identity Omniauth Responses"

    let(:super_admin) { create(:super_admin) }
    let(:email) { "example@example.com" }
    let(:user_email) { email }

    before { close_registration! }

    scenario "Allow user to register" do
      visit "/"
      expect(page).to have_content("Registration has closed temporarily")

      sign_in_as(super_admin)

      click_link("Closed registration user")
      fill_in("Email", with: email)
      click_on("Save")

      expect(page).to have_content("New closed registration user created")

      click_link("Sign out")

      visit "/closed_registration_exception"

      click_on("Start now")

      expect_page_to_have(path: "/registration/course-start-date", submit_form: true) do
        expect(page).to have_text("NPQ start dates are usually every February and October.")
      end
    end

    scenario "When user is not whitelisted" do
      visit "/"
      expect(page).to have_content("Registration has closed temporarily")

      visit "/closed_registration_exception"

      click_on("Start now")

      expect_page_to_have(path: "/registration/closed")
    end
  end

  context "when using email updates" do
    before { close_registration! }

    scenario "Register to email and unsubscribe" do
      visit "/"
      click_button "Sign in to your account"

      visit new_email_update_path

      # choose "Yes" # its not working for some reason
      find_all(:label)[0].click # HACK: instead `choose "Yes"`
      click_button "Request email updates"

      expect(page).to have_content("Your email request has been set up")

      user = User.last
      expect(user.email_updates_status).to eq("senco")

      visit "/email_updates/unsubscribe?unsubscribe_key=#{user.email_updates_unsubscribe_key}"
      expect(page).to have_content("Are you sure you want to unsubscribe?")
      click_button "Unsubscribe"

      expect(page).to have_content("You have unsubscribed")
      expect(user.reload.email_updates_status).to eq("empty")
    end

    scenario "Invalid unsubscribe link" do
      visit "/email_updates/unsubscribe?unsubscribe_key=user.email_updates_unsubscribe_key"
      expect(page).to have_content("Are you sure you want to unsubscribe?")
      click_button "Unsubscribe"

      expect(page).to have_content("Invalid link")
    end
  end

private

  def close_registration!
    Flipper.disable(Feature::REGISTRATION_OPEN)
  end

  def open_registration!
    Flipper.enable(Feature::REGISTRATION_OPEN)
  end
end
