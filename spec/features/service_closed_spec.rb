require "rails_helper"

RSpec.feature "Service is hard closed", type: :feature do
  include Helpers::AdminLogin
  include Helpers::JourneyAssertionHelper
  include Helpers::JourneyStepHelper

  scenario "Service close date has passed" do
    close_registration!

    visit "/"
    expect(page).to have_content("Registration for NPQs has closed temporarily")
    expect(page).to be_axe_clean

    page.click_link("Sign up for an email")
    expect(page).to have_content("What’s your email address?")
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

    expect(page).to have_content("Registration for NPQs has closed temporarily")
  end

  context "when service is closed" do
    include_context "Stub Get An Identity Omniauth Responses"

    let(:super_admin) { create(:super_admin) }
    let(:email) { "example@example.com" }
    let(:user_email) { email }

    before { close_registration! }

    scenario "Allow user to register" do
      visit "/"
      expect(page).to have_content("Registration for NPQs has closed temporarily")

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
      expect(page).to have_content("Registration for NPQs has closed temporarily")

      visit "/closed_registration_exception"

      click_on("Start now")

      expect_page_to_have(path: "/registration/closed")
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
