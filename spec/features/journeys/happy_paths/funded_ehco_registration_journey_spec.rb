require "rails_helper"

RSpec.feature "Happy journeys", :with_cohorts, :with_default_schedules, type: :feature do
  include Helpers::JourneyAssertionHelper
  include Helpers::JourneyStepHelper
  include ApplicationHelper

  before { create(:school, :eligible_with_urn_and_address) }

  include_context "retrieve latest application data"
  include_context "Stub Get An Identity Omniauth Responses"
  include_context "with stubbed Teacher Auth OmniAuth responses"
  include_context "with stubbed Teaching Record System person API"

  context "when JavaScript is enabled", :js do
    scenario("funded EHCO registration journey") { run_scenario(js: true) }
  end

  context "when JavaScript is disabled", :no_js do
    scenario("funded EHCO registration journey") { run_scenario(js: false) }
  end

  def run_scenario(js:)
    complete_journey_as_far_as_choosing_a_work_setting(
      course: "Early headship coaching offer",
      work_setting: "Primary school (5 to 11)",
    )

    choose_a_school(js:, name: "open")

    expect_page_to_have(path: "/registration/npqh-status", submit_form: true) do
      page.choose("I’ve completed it", visible: :all)
    end

    expect_page_to_have(path: "/registration/ehco-new-headteacher", submit_form: true) do
      page.choose("Yes", visible: :all)
    end

    expect_page_to_have(path: "/registration/ehco-possible-funding", click_continue: false) do
      click_link "Continue to register"
    end

    expect_page_to_have(path: "/registration/choose-your-provider", submit_form: true) do
      expect(page).to have_text("Select your provider")
      page.choose("Teach First", visible: :all)
    end

    expect_page_to_have(path: "/registration/share-provider", submit_form: true) do
      expect(page).to have_text("Sharing your NPQ information")
      page.check("Yes, I agree to share my information", visible: :all)
    end

    check_back_journey_is_correct

    check_answers_log_in_and_submit do
      expect_check_answers_page_to_have_answers(
        {
          "DfE scholarship funding" => "Eligible",
          "Cohort" => course_start_cohort_description,
          "Working in England" => "Yes",
          "Work setting" => "Primary school (5 to 11)",
          "Course" => "Early headship coaching offer",
          "Provider" => "Teach First",
          "Workplace" => "open manchester school – street 1, manchester",
          "First 5 years of headship" => "Yes",
          "Headship NPQ stage" => "I’ve completed it",
        },
      )
    end

    expect_applicant_reached_end_of_journey

    if User.last.applications.count == 1
      navigate_to_page(path: "/accounts/user_registrations/#{User.last.applications.last.id}", axe_check: false, submit_form: false) do
        expect(page).to have_text("Teach First")
        expect(page).to have_text("Your Early headship coaching offer registration")
      end
    else
      navigate_to_page(path: "/account", axe_check: false, submit_form: false) do
        expect(page).to have_text("Teach First")
        expect(page).to have_text("Your NPQ registration")
      end
    end

    visit "/registration/check-answers"
    expect(page).to have_current_path("/")

    expect(retrieve_latest_application_user_data).to match(user_attributes_from_stubbed_callback_response)

    deep_compare_application_data(
      "accepted_at" => nil,
      "cohort_id" => Cohort.current.id,
      "course_id" => Course.find_by(identifier: "npq-early-headship-coaching-offer").id,
      "schedule_id" => nil,
      "ecf_id" => latest_application.ecf_id,
      "eligible_for_funding" => true,
      "employer_name" => nil,
      "employment_type" => nil,
      "employment_role" => nil,
      "funded_place" => nil,
      "funding_choice" => nil,
      "funding_eligiblity_status_code" => "funded",
      "headteacher_status" => "yes_in_first_five_years",
      "kind_of_nursery" => nil,
      "lead_provider_id" => LeadProvider.find_by(name: "Teach First").id,
      "notes" => nil,
      "private_childcare_provider_id" => nil,
      "school_id" => School.find_by(urn: "100000").id,
      "itt_provider_id" => nil,
      "lead_mentor" => false,
      "lead_provider_approval_status" => "pending",
      "participant_outcome_state" => nil,
      "targeted_delivery_funding_eligibility" => false,
      "targeted_support_funding_eligibility" => false,
      "teacher_catchment" => "england",
      "teacher_catchment_country" => "United Kingdom of Great Britain and Northern Ireland",
      "teacher_catchment_iso_country_code" => "GBR",
      "teacher_catchment_synced_to_ecf" => false,
      "training_status" => nil,
      "ukprn" => nil,
      "primary_establishment" => false,
      "referred_by_return_to_teaching_adviser" => nil,
      "number_of_pupils" => nil,
      "tsf_primary_eligibility" => false,
      "tsf_primary_plus_eligibility" => false,
      "works_in_childcare" => false,
      "works_in_nursery" => nil,
      "works_in_school" => true,
      "work_setting" => "primary_school",
      "senco_in_role" => nil,
      "senco_start_date" => nil,
      "on_submission_trn" => nil,
      "review_status" => nil,
      "raw_application_data" => {
        "can_share_choices" => "1",
        "check_funding" => "yes",
        "course_start_cohort" => course_start_cohort_value,
        "course_identifier" => "npq-early-headship-coaching-offer",
        "declared_previous_funding" => "no",
        "ehco_new_headteacher" => "yes",
        "email_template" => "ehco_scholarship_funding",
        "funding_eligiblity_status_code" => "funded",
        "institution_identifier" => "School-100000",
        "institution_name" => js ? "" : "open",
        "lead_provider_id" => LeadProvider.find_by(name: "Teach First").id.to_s,
        "pre_login_funding_eligiblity_status_code" => "funded",
        "npqh_status" => "completed_npqh",
        "submitted" => true,
        "teacher_catchment" => "england",
        "teacher_catchment_country" => nil,
        "works_in_school" => "yes",
        "works_in_childcare" => "no",
        "work_setting" => "primary_school",
      },
    )
  end
end
