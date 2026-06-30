require "rails_helper"

RSpec.feature "Service is closed", :no_js, type: :feature do
  include Helpers::AdminLogin
  include Helpers::JourneyAssertionHelper
  include Helpers::JourneyStepHelper

  context "when registration is closed" do
    include_context "Stub Get An Identity Omniauth Responses"

    before { close_registration! }

    scenario "Service prompts to register for email updates using DfE Identity login" do
      visit "/"
      expect(page).to have_current_path(registration_closed_path)
      expect(page).to have_content("Registration is temporarily closed")
      expect(page).to be_accessible

      page.click_button("Sign up for email updates")
      expect(page).to have_current_path(new_email_update_path)
      expect(page).to have_content("Get email updates about registration opening")
      expect(page).to be_accessible
    end

    context "when a user has a teacher auth account" do
      include_context "with stubbed Teacher Auth OmniAuth responses"
      include_context "with stubbed Teaching Record System person API"

      before do
        create(:user, :with_teacher_auth, :with_verified_trn, email: "user@example.com", trn: "1234567")
      end

      scenario "Service prompts to log in with One Login" do
        visit "/"
        click_button("Sign in to your DfE Identity account")
        expect(page).to have_content "Your account is now registered with One Login. Please sign in using your One Login account."
        expect(page).to have_current_path "/registration_closed?one_login=true"
        expect(page).not_to have_content "Sign up for email updates to find out when registration reopens."
        expect(page).not_to have_button "Sign up for email updates"

        click_button("Sign in to your One Login account")
        expect(page).to have_current_path account_path
      end
    end

    context "when registration reopens" do
      before { open_registration! }

      scenario "registration closed page redirects to home page" do
        visit registration_closed_path
        expect(page).to have_current_path("/")
      end
    end
  end

  context "when registration closes whilst in the middle of a registration journey" do
    include_context "with stubbed Teacher Auth OmniAuth responses"
    include_context "with stubbed Teaching Record System person API"

    before do
      visit "/"
      page.click_button("Start now")
      choose_course_start_date
      close_registration!
      page.click_button("Continue")
    end

    scenario "the registration closed step is shown" do
      expect(page).to have_current_path(registration_wizard_show_path(:closed))
      expect(page).to have_content("Registration has closed temporarily")
    end

    context "when registration reopens" do
      before { open_registration! }

      scenario "registration closed step redirects to home page" do
        visit registration_wizard_show_path(:closed)
        expect(page).to have_current_path("/")
      end
    end
  end

  context "when using late registration" do
    include_context "with stubbed Teacher Auth OmniAuth responses"
    include_context "with stubbed Teaching Record System person API"

    let(:super_admin) { create(:super_admin) }
    let(:email) { "example@example.com" }
    let(:other_email) { "example2@example.com" }
    let(:user_email) { email }

    before { close_registration! }

    scenario "Allow user to register using Teacher Auth" do
      visit "/"
      expect(page).to have_content("Registration is temporarily closed")

      sign_in_as(super_admin)

      visit "/admin/registration-closed/closed-registration-users"
      fill_in("Email address", with: email)
      click_on("Add user")

      expect(page).to have_content("Added #{email}")

      click_link("Sign out")
      visit "/closed_registration_exception"
      click_on("Start now")

      expect(page).to have_content("Registration has closed temporarily")

      Flipper.enable(Feature::CLOSED_REGISTRATION_ENABLED)
      visit "/closed_registration_exception"
      click_on("Start now")
      expect(page).to have_current_path("/registration/course-start-date")
    end

    scenario "When user is deleted" do
      Flipper.enable(Feature::CLOSED_REGISTRATION_ENABLED)
      visit "/closed_registration_exception"

      click_on("Start now")
      expect(page).to have_content("Registration has closed temporarily")

      sign_in_as(super_admin)

      visit "/admin/registration-closed/closed-registration-users"
      fill_in("Email", with: email)
      click_on("Add user")

      expect(page).to have_content("Added #{email}")

      visit "/closed_registration_exception"

      click_on("Start now")

      choose_course_start_date

      visit "/admin/registration-closed/closed-registration-users"

      click_link("Remove access")
      click_link("Remove access")
      expect(page).to have_content("Access removed for #{email}")

      visit "/closed_registration_exception"

      click_on("Start now")

      expect_page_to_have(path: "/registration/closed") do
        expect(page).to have_content("Registration has closed temporarily")
      end
    end

    scenario "When user is deleted and has no account" do
      visit "/closed_registration_exception"

      click_on("Start now")
      expect(page).to have_content("Registration has closed temporarily")

      sign_in_as(super_admin)

      visit "/admin/registration-closed/closed-registration-users"
      fill_in("Email", with: other_email)
      click_on("Add user")

      expect(page).to have_content("Added #{other_email}")

      click_link("Remove access")
      click_link("Remove access")

      expect(page).to have_content("Access removed for #{other_email}")

      visit "/closed_registration_exception"

      click_on("Start now")

      expect_page_to_have(path: "/registration/closed") do
        expect(page).to have_content("Registration has closed temporarily")
      end
    end

    scenario "When user is not whitelisted" do
      visit "/"
      expect(page).to have_content("Registration is temporarily closed")

      visit "/closed_registration_exception"

      click_on("Start now")

      expect_page_to_have(path: "/registration/closed")
    end

    context "when registration reopens" do
      before do
        visit "/"
        sign_in_as(super_admin)
        visit "/admin/registration-closed/closed-registration-users"
        fill_in("Email address", with: email)
        click_on("Add user")
        click_link("Sign out")
        open_registration!
      end

      scenario "the late registration page redirects to the home page" do
        visit "/closed_registration_exception"
        expect(page).to have_current_path("/")
      end
    end

    context "when teacher auth is deactivated" do
      before do
        allow(Rails.configuration.x.teacher_auth).to receive(:enabled).and_return(false)
      end

      scenario "the late registration page redirects to the home page" do
        visit "/closed_registration_exception"
        expect(page).to have_current_path("/registration_closed")
      end
    end
  end

  context "when using email updates" do
    include_context "Stub Get An Identity Omniauth Responses"

    before { close_registration! }

    scenario "Register to email and unsubscribe" do
      visit "/"
      click_button "Sign in to your DfE Identity account"
      click_link "Request email updates"
      page.choose("Yes", visible: :all)
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

      expect(page).to have_content("Invalid unsubscribe link")
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
