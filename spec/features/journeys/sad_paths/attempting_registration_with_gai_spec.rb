require "rails_helper"

RSpec.feature "Registration whilst already signed in with DfE Identity", :no_js, :with_cohorts, type: :feature do
  include Helpers::JourneyAssertionHelper
  include Helpers::JourneyStepHelper

  before { allow(Sentry).to receive(:capture_message) }

  let(:user) { User.find_by(email: "user@example.com") }

  include_context "Stub Get An Identity Omniauth Responses"

  scenario "attempting to register whilst signed in with DfE Sign In" do
    allow(Feature).to receive(:registration_closed?).and_return(true)

    navigate_to_page(path: "/registration_closed", submit_form: false, axe_check: false) do
      page.click_button("Sign in to your DfE Identity account")
    end

    expect_page_to_have(path: "/account")
    expect(page).to have_link("DfE Identity account")
    expect(page).to have_link("Sign out")

    allow(Feature).to receive(:registration_closed?).and_return(false)

    complete_journey_as_far_as_check_answers

    page.click_button("Continue")

    expect_page_to_have(path: "/registration/continue-to-login", submit_form: false)

    # attempt to bypass login
    visit "/registration/check-answers-and-submit"

    expect_page_to_have(path: "/registration/continue-to-login", submit_form: false)
    expect(Sentry).to have_received(:capture_message)
  end

  scenario "visiting course page directly whilst not being signed in and registration is closed" do
    allow(Feature).to receive(:registration_closed?).and_return(true)

    visit("/registration/course_start_date")

    expect_page_to_have(path: "/registration/closed")
    expect(Sentry).not_to have_received(:capture_message)
  end
end
