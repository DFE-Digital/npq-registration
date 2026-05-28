require "rails_helper"

RSpec.feature "Registration whilst already signed in with DfE Identity", :no_js, type: :feature do
  include Helpers::JourneyAssertionHelper

  before { allow(Sentry).to receive(:capture_message) }

  let(:user) { User.find_by(email: "user@example.com") }

  include_context "Stub Get An Identity Omniauth Responses"

  scenario "attempting to register whilst signed in with DfE Sign In" do
    allow(Feature).to receive(:registration_closed?).and_return(true)

    navigate_to_page(path: "/registration_closed", submit_form: false, axe_check: false) do
      page.click_button("Sign in to your DfE Identity account")
    end

    expect(page).to have_current_path("/account")

    allow(Feature).to receive(:registration_closed?).and_return(false)

    expect(page).to have_link("DfE Identity account")
    expect(page).to have_link("Sign out")

    visit("/registration/course-start-date")

    expect_page_to_have(path: "/") do
      expect(page).not_to have_link("DfE Identity account")
      expect(page).not_to have_link("Sign out")

      expect(page).to have_css(".govuk-notification-banner", text: /restart.*registration/i)

      expect(Sentry).to have_received(:capture_message)
    end
  end
end
