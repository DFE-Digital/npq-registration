require "rails_helper"

RSpec.feature "Account", type: :feature do
  include Helpers::JourneyAssertionHelper

  include_context "Stub Get An Identity Omniauth Responses"

  let(:user_uid) { SecureRandom.uuid }
  let(:user) { create(:user, uid: user_uid, email: "user@example.com") }
  let(:cohort) { create(:cohort, start_year: 2025) }
  let(:application) { create(:application, user:, cohort:) }

  before { application }

  describe "accounts page" do
    scenario "when not logged in, it redirects to sign in" do
      visit "/account"
      expect(page).to be_accessible
      expect(page).to have_current_path("/sign-in")
    end

    context "when logged in" do
      before do
        navigate_to_page(path: "/", submit_form: false, axe_check: false) do
          page.click_button("Start now")
        end
      end

      scenario "when logged in, it shows the application details" do
        visit "/account"

        expect(page).to have_current_path("/accounts/user_registrations/#{application.id}")
        expect(page).to have_summary_item("Course start", "2025")
      end

      context "when the user's previous application is in a 2026 cohort" do
        let(:cohort) { create(:cohort, start_year: 2026) }

        scenario "it shows the correct cohort description" do
          visit "/account"

          expect(page).to have_summary_item("Course start", "Spring 2026")
        end
      end
    end
  end

  describe "accounts user registration page" do
    scenario "when not logged in, it redirects to sign in" do
      visit(accounts_user_registration_path(application.id))

      expect(page).to have_current_path("/sign-in")
    end
  end
end
