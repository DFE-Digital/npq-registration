require "rails_helper"

RSpec.feature "Account", :no_js, type: :feature do
  include Helpers::JourneyAssertionHelper
  include ActionView::Helpers::SanitizeHelper

  include_context "with stubbed Teacher Auth OmniAuth responses"
  include_context "with stubbed Teaching Record System person API"

  let(:user_uid) { user.uid }
  let(:user) { create(:user, :with_teacher_auth, email: "user@example.com") }
  let(:cohort) { create(:cohort, start_year: 2025) }
  let(:application) { create(:application, user:, cohort:) }

  before { application }

  describe "accounts page" do
    scenario "when not logged in, it redirects to sign in" do
      visit "/account"
      expect(page).to be_accessible
      expect(page).to have_current_path("/")
    end

    context "when logged in" do
      before do
        navigate_to_page(path: "/", submit_form: false, axe_check: false) do
          page.click_button("Start now")
        end
      end

      scenario "it shows the it shows the application details" do
        visit "/account"
        expect(page).to have_current_path("/accounts/user_registrations/#{application.id}")
      end

      scenario "it shows the course start cohort" do
        visit "/account"
        expect(page).to have_summary_item("Course start", "2025")
      end

      scenario "it shows the registration details" do
        visit "/accounts/user_registrations/#{application.id}"

        expect(page).to have_css("h1", text: "Your Senior leadership registration")
        expect(page).to have_text("Submitted #{application.created_at.to_date.to_fs(:govuk)}")
        expect(page).to have_text("Registration ID: #{application.ecf_id}")
        expect(page).to have_summary_item("Registration submitted", application.created_at.to_date.to_fs(:govuk))
        expect(page).to have_summary_item("Provider", application.lead_provider.name)
        expect(page).to have_summary_item("DfE scholarship funding", "Not eligible")
        expect(page).to have_summary_item("Working in England", "Yes")
        expect(page).to have_summary_item("Workplace", application.school.name)
      end

      scenario "it shows the application progress, personal details and next steps" do
        visit "/accounts/user_registrations/#{application.id}"

        expect(page).to have_summary_item("Application status", "Awaiting provider")
        expect(page).to have_text("Your provider will contact you with instructions on how to apply for the course.")
        expect(page).to have_text("You do not need to do anything until they contact you.")

        expect(page).to have_summary_item("Your details", "Update your personal details on GOV.UK One Login")
        expect(page).to have_link("GOV.UK One Login (opens in a new tab)", href: Rails.configuration.x.teacher_auth.onelogin_home_uri)

        expect(page).to have_css("h2", text: "Next steps")
        expect(page).to have_text("Once you’ve applied with your provider, they’ll:")
        expect(page).to have_link("Start now", href: "/registration/course-start-date")
      end

      scenario "it does not show the removed sections" do
        visit "/accounts/user_registrations/#{application.id}"

        expect(page).not_to have_text("Work details")
        expect(page).not_to have_text("We’d like your feedback")
        expect(page).not_to have_text("Registration successfully submitted")
      end

      context "when the user's previous application is in the Spring 2026 cohort" do
        let(:cohort) { create(:cohort, start_year: 2026, suffix: "a") }

        scenario "it shows the correct course start answer" do
          visit "/account"

          expect(page).to have_summary_item("Autumn 2026 start", "No, I already started in Spring")
        end
      end

      context "when the user's previous application is in the Autumn 2026 cohort" do
        let(:cohort) { create(:cohort, start_year: 2026, suffix: "b") }

        scenario "it shows the correct course start answer" do
          visit "/account"

          expect(page).to have_summary_item("Autumn 2026 start", "Yes")
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

      expect(page).to have_current_path("/")
    end
  end
end
