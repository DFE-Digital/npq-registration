require "rails_helper"

RSpec.feature "Registration complete page", :no_js, type: :feature do
  include Helpers::JourneyAssertionHelper

  include_context "with stubbed Teacher Auth OmniAuth responses"
  include_context "with stubbed Teaching Record System person API"

  let(:user_uid) { user.uid }
  let(:user) { create(:user, :with_teacher_auth, email: "user@example.com") }
  let(:cohort) { create(:cohort, start_year: 2026, suffix: "b") }
  let(:application) { create(:application, user:, cohort:) }

  before { application }

  context "when not logged in" do
    scenario "Redirect to sign in" do
      visit registration_complete_accounts_user_registration_path(application)

      expect(page).to have_current_path("/")
    end
  end

  context "when logged in" do
    before do
      navigate_to_page(path: "/", submit_form: false, axe_check: false) do
        page.click_button("Start now")
      end
    end

    scenario "Show the registration confirmation" do
      visit registration_complete_accounts_user_registration_path(application)

      expect(page).to be_accessible
      expect(page).to have_css("h1", text: "Registration complete")
      expect(page).to have_text("Your Registration ID")
      expect(page).to have_text(application.ecf_id)
      expect(page).to have_text("We have sent you a confirmation email.")
      expect(page).to have_css("h2", text: "What happens next")
      expect(page).to have_text("We’ve sent your registration to #{application.lead_provider.name}, your provider.")
      expect(page).to have_text("They will aim to contact you within 5 working days and ask you to complete their application form.")
      expect(page).to have_link("Review a summary of your registration", href: accounts_user_registration_path(application))
    end

    scenario "Don't show another user's registration" do
      other_application = create(:application)

      visit registration_complete_accounts_user_registration_path(other_application)

      expect(page).to have_text("The page you were looking for doesn’t exist.")
    end
  end
end
