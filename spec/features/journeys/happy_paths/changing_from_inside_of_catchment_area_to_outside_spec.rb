require "rails_helper"

RSpec.feature "Happy journeys", :no_js, :with_cohorts, :with_default_schedules, type: :feature do
  include Helpers::JourneyAssertionHelper
  include Helpers::JourneyStepHelper
  include ApplicationHelper

  include_context "retrieve latest application data"
  include_context "with stubbed Teacher Auth OmniAuth responses"
  include_context "with stubbed Teaching Record System person API"

  let(:school) { create(:school, :eligible_with_urn_and_address) }

  before { school }

  scenario "registration journey changing from inside of catchment area to outside" do
    navigate_to_page(path: "/", submit_form: false, axe_check: false) do
      expect(page).to have_text("Before you start")
      page.click_button("Start now")
    end

    choose_course_start_date

    expect_page_to_have(path: "/registration/check-funding", submit_form: true) do
      expect(page).to have_text("Check if you’re eligible for DfE scholarship funding")
      click_button("Check funding")
    end

    choose_teacher_catchment(js: false, region: "Yes")

    expect_page_to_have(path: "/registration/choose-your-npq", submit_form: true) do
      expect(page).to have_text("Which NPQ do you want to do?")
      page.choose("Senior leadership", visible: :all)
    end

    expect_page_to_have(path: "/registration/funding-history", submit_form: true) do
      page.choose("No", visible: :all)
    end

    # TODO: aria-expanded
    expect_page_to_have(path: "/registration/work-setting", axe_check: false, submit_form: true) do
      page.choose("A school", visible: :all)
      page.choose("Primary school (5 to 11)", visible: :all)
    end

    choose_a_school(js: false, name: "open")

    expect_page_to_have(path: "/registration/possible-funding", submit_form: false) do
      page.click_button("Continue to register")
    end

    expect_page_to_have(path: "/registration/choose-your-provider", submit_form: true) do
      expect(page).to have_text("Select your provider")
      page.choose("Teach First", visible: :all)
    end

    expect_page_to_have(path: "/registration/share-provider", submit_form: true) do
      expect(page).to have_text("Sharing your NPQ information")
      page.check("Yes, I agree to share my information", visible: :all)
    end

    expect_page_to_have(path: "/registration/check-answers", submit_form: false) do
      expect_check_answers_page_to_have_answers(
        {
          "DfE scholarship funding" => "Eligible",
          "Cohort" => course_start_cohort_description,
          "Course" => "Senior leadership",
          "Work setting" => "Primary school (5 to 11)",
          "Provider" => "Teach First",
          "Working in England" => "Yes",
        },
      )
      expect(page).to have_content 'funding_eligiblity_status_code: "funded"'

      page.click_link("Change", href: "/registration/teacher-catchment/change")
    end

    # TODO: aria-expanded
    expect_page_to_have(path: "/registration/teacher-catchment/change", axe_check: false, submit_form: true) do
      page.choose("No", visible: :all)
    end

    expect_page_to_have(path: "/registration/ineligible-for-funding/change", submit_form: false) do
      click_link("Continue to register")
    end

    expect_page_to_have(path: "/registration/funding-your-npq", submit_form: true) do
      expect(page).to have_text("How are you funding your course?")
      page.choose "I am paying", visible: :all
    end

    expect_page_to_have(path: "/registration/choose-your-provider", submit_form: true) do
      page.choose("Teach First", visible: :all)
    end

    expect_page_to_have(path: "/registration/share-provider", submit_form: true) do
      page.check("Yes, I agree to share my information", visible: :all)
    end

    check_answers_log_in_and_submit do
      expect_check_answers_page_to_have_answers(
        {
          "Cohort" => course_start_cohort_description,
          "Course" => "Senior leadership",
          "Course funding" => "I am paying",
          "DfE scholarship funding" => "Not eligible",
          "Provider" => "Teach First",
          "Work setting" => "Primary school (5 to 11)",
          "Working in England" => "No",
          "Workplace" => "open manchester school – street 1, manchester",
        },
      )
      expect(page).to have_content 'funding_eligiblity_status_code: "not_in_england"'
    end

    expect_applicant_reached_end_of_journey

    expect(retrieve_latest_application_user_data).to match(user_attributes_from_stubbed_callback_response)

    deep_compare_application_data(
      "accepted_at" => nil,
      "cohort_id" => Cohort.current.id,
      "course_id" => Course.find_by(identifier: "npq-senior-leadership").id,
      "schedule_id" => nil,
      "ecf_id" => latest_application.ecf_id,
      "eligible_for_funding" => false,
      "employer_name" => nil,
      "employment_type" => nil,
      "employment_role" => nil,
      "funded_place" => nil,
      "funding_choice" => "self",
      "funding_eligiblity_status_code" => "not_in_england",
      "itt_provider_id" => nil,
      "lead_mentor" => false,
      "lead_provider_approval_status" => "pending",
      "participant_outcome_state" => nil,
      "headteacher_status" => nil,
      "kind_of_nursery" => nil,
      "lead_provider_id" => LeadProvider.find_by(name: "Teach First").id,
      "notes" => nil,
      "private_childcare_provider_id" => nil,
      "referred_by_return_to_teaching_adviser" => nil,
      "school_id" => nil,
      "targeted_delivery_funding_eligibility" => false,
      "targeted_support_funding_eligibility" => false,
      "teacher_catchment" => "another",
      "teacher_catchment_country" => nil,
      "teacher_catchment_iso_country_code" => nil,
      "teacher_catchment_synced_to_ecf" => false,
      "training_status" => nil,
      "ukprn" => nil,
      "primary_establishment" => false,
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
        "course_identifier" => "npq-senior-leadership",
        "declared_previous_funding" => "no",
        "email_template" => "not_england_wrong_catchment",
        "funding" => "self",
        "funding_eligiblity_status_code" => "not_in_england",
        "institution_identifier" => "School-#{school.urn}",
        "institution_name" => "open",
        "lead_provider_id" => LeadProvider.find_by(name: "Teach First").id.to_s,
        "pre_login_funding_eligiblity_status_code" => "not_in_england",
        "submitted" => true,
        "teacher_catchment" => "another",
        "teacher_catchment_country" => nil,
        "works_in_school" => "yes",
        "works_in_childcare" => "no",
        "work_setting" => "primary_school",
      },
    )
  end
end
