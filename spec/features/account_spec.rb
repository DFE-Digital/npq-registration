require "rails_helper"

RSpec.feature "Account", type: :feature do
  include Helpers::JourneyAssertionHelper
  include ActionView::Helpers::SanitizeHelper

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

      scenario "it shows the accounts user registration page" do
        expect(page).to have_current_path("/accounts/user_registrations/#{application.id}")
      end

      scenario "it shows the course start cohort" do
        expect(page).to have_summary_item("Course start", "2025")
      end

      context "when the user's previous application is in a 2026 cohort" do
        let(:cohort) { create(:cohort, start_year: 2026) }

        scenario "it shows the correct cohort description" do
          visit "/account"

          expect(page).to have_summary_item("Course start", "Spring 2026")
        end
      end

      # Deliberately written like this
      #  to pick up if a new funding_eligiblity_status constant is added to FundingEligibility,
      #  but it is not correctly added to FundingEligibility::FUNDING_STATUS_CODE_DESCRIPTIONS
      #  and the funding_details locale strings.
      FundingEligibility.constants
        .excluding(:MissingMandatoryInstitution,
                   :FUNDING_STATUS_CODE_DESCRIPTIONS,
                   :FUNDED_ELIGIBILITY_RESULT,
                   :SUBJECT_TO_REVIEW).each do |funding_eligiblity_status|
                     context "when the application funding_eligiblity_status_code is #{funding_eligiblity_status}" do
                       let(:application) { create(:application, :without_funded_place, user:, cohort:, funding_eligiblity_status_code:) }
                       let(:funding_eligiblity_status_code) { FundingEligibility.const_get(funding_eligiblity_status) }
                       let(:funding_details_key) { FundingEligibility::FUNDING_STATUS_CODE_DESCRIPTIONS[funding_eligiblity_status_code] }

                       scenario "it shows scholarship funding details" do
                         visit "/accounts/user_registrations/#{application.id}"

                         expect(page).to(
                           have_summary_item(
                             "Scholarship funding",
                             strip_tags(
                               I18n.t(
                                 "funding_details.#{FundingEligibility::FUNDING_STATUS_CODE_DESCRIPTIONS[funding_eligiblity_status_code]}",
                                 course_name: "the Senior leadership NPQ",
                               ),
                             ),
                           ),
                         )
                       end
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
