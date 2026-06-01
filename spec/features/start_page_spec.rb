require "rails_helper"

RSpec.feature "Start page", :no_js, type: :feature do
  include Helpers::JourneyAssertionHelper

  include_context "with stubbed Teacher Auth OmniAuth responses"
  include_context "with stubbed Teaching Record System person API"

  let(:user_uid) { "urn:fdc:gov.uk:2022:#{SecureRandom.alphanumeric(43)}" }
  let(:user) { create(:user, :with_teacher_auth, uid: user_uid) }
  let(:application) { create(:application, user:) }

  scenario "Navigate to home" do
    visit "/"

    expect(page).to be_accessible
    expect(page).to have_text("Before you start")
  end

  context "when the user has no applications" do
    scenario "Start now button starts journey" do
      visit "/"
      page.click_button("Start now")

      expect_page_to_have(path: "/registration/course-start-date")
    end

    scenario "Sign in button goes to account page" do
      visit "/"
      page.click_button("Sign in")

      expect(page).to have_current_path("/account")
    end
  end

  context "when the user has an existing application" do
    before { application }

    scenario "Start now button starts journey" do
      visit "/"
      page.click_button("Start now")

      expect_page_to_have(path: "/registration/course-start-date")
    end

    scenario "Sign in button goes to application details page" do
      visit "/"
      page.click_button("Sign in")

      expect(page).to have_current_path("/accounts/user_registrations/#{application.id}")
    end
  end

  context "when the user has more than one application" do
    before { create_list(:application, 2, user:) }

    scenario "Sign in button goes to account page" do
      visit "/"
      page.click_button("Sign in")

      expect(page).to have_current_path("/account")
    end
  end
end
