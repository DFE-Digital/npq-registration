require "rails_helper"

RSpec.feature "Happy journeys", :no_js, :with_cohorts, :with_default_schedules, type: :feature do
  include Helpers::JourneyAssertionHelper
  include Helpers::JourneyStepHelper
  include ApplicationHelper

  include_context "retrieve latest application data"
  include_context "with stubbed Teacher Auth OmniAuth responses"
  include_context "with stubbed Teaching Record System person API"

  let(:school) { create(:school, :eligible_with_urn_and_address) }

  before { create(:eligibility_list_entry, :pp50_school, identifier: school.urn) }

  scenario "registration journey changing do you work in a school from yes to no" do
    complete_journey_as_far_as_choosing_a_work_setting(
      course: "Leading teaching",
      work_setting: "Primary school (5 to 11)",
    )

    choose_a_school(js: false, name: "open")

    expect_page_to_have(path: "/registration/possible-funding", submit_form: true) do
      expect(page).to have_text("You’re eligible for scholarship funding")
    end

    choose_provider_share_information_and_check_answers(provider: "Teach First")

    expect_page_to_have(path: "/registration/check-answers", submit_form: false) do
      expect_check_answers_page_to_have_answers(
        {
          "Cohort" => course_start_cohort_description,
          "Course" => "Leading teaching",
          "DfE scholarship funding" => "Eligible",
          "Provider" => "Teach First",
          "Work setting" => "Primary school (5 to 11)",
          "Workplace" => "open manchester school – street 1, manchester",
        },
      )
      expect(page).to have_content 'funding_eligiblity_status_code: "funded"'

      page.click_link("Change", href: "/registration/work-setting/change")
    end

    expect_page_to_have(path: "/registration/work-setting/change", submit_form: true) do
      page.choose("Another setting", visible: :all)
    end

    expect_page_to_have(path: "/registration/your-employment/change", submit_form: true) do
      expect(page).to have_text("How are you employed?")
      page.choose("In an independent hospital education organisation", visible: :all)
    end

    expect_page_to_have(path: "/registration/your-employer/change", submit_form: true) do
      page.fill_in "What organisation are you employed by?", with: "Big company"
    end

    expect_page_to_have(path: "/registration/ineligible-for-funding/change", submit_form: false) do
      expect(page).to have_text("DfE scholarship funding")
      page.click_on("Continue to register")
    end

    expect_page_to_have(path: "/registration/funding-your-npq", submit_form: true) do
      expect(page).to have_text("How are you funding your course?")
      page.choose("I am paying", visible: :all)
    end

    expect_page_to_have(path: "/registration/choose-your-provider", submit_form: true) do
      expect(page).to have_text("Select your provider")
      page.choose("Teach First", visible: :all)
    end

    expect_page_to_have(path: "/registration/share-provider", submit_form: true) do
      expect(page).to have_text("Sharing your NPQ information")
      page.check("Yes, I agree to share my information", visible: :all)
    end

    check_answers_log_in_and_submit do
      expect_check_answers_page_to_have_answers(
        {
          "Cohort" => course_start_cohort_description,
          "Course funding" => "I am paying",
          "Course" => "Leading teaching",
          "DfE scholarship funding" => "Not eligible",
          "Employer" => "Big company",
          "Employment type" => "In an independent hospital education organisation",
          "Provider" => "Teach First",
          "Work setting" => "Another setting",
          "Working in England" => "Yes",
        },
      )
      expect(page).to have_content 'funding_eligiblity_status_code: "ineligible_establishment_type"'
    end

    expect_applicant_reached_end_of_journey

    expect(retrieve_latest_application_user_data).to match(user_attributes_from_stubbed_callback_response)

    deep_compare_application_data(
      "accepted_at" => nil,
      "cohort_id" => Cohort.current.id,
      "course_id" => Course.find_by(identifier: "npq-leading-teaching").id,
      "schedule_id" => nil,
      "ecf_id" => latest_application.ecf_id,
      "eligible_for_funding" => false,
      "employer_name" => "Big company",
      "employment_type" => "hospital_school",
      "employment_role" => nil,
      "funded_place" => nil,
      "funding_choice" => "self",
      "funding_eligiblity_status_code" => "ineligible_establishment_type",
      "headteacher_status" => nil,
      "kind_of_nursery" => nil,
      "itt_provider_id" => nil,
      "lead_mentor" => false,
      "lead_provider_approval_status" => "pending",
      "participant_outcome_state" => nil,
      "referred_by_return_to_teaching_adviser" => nil,
      "lead_provider_id" => LeadProvider.find_by(name: "Teach First").id,
      "notes" => nil,
      "private_childcare_provider_id" => nil,
      "school_id" => nil,
      "targeted_delivery_funding_eligibility" => false,
      "targeted_support_funding_eligibility" => false,
      "teacher_catchment" => "england",
      "teacher_catchment_country" => "United Kingdom of Great Britain and Northern Ireland",
      "teacher_catchment_iso_country_code" => "GBR",
      "teacher_catchment_synced_to_ecf" => false,
      "training_status" => nil,
      "ukprn" => nil,
      "primary_establishment" => false,
      "number_of_pupils" => 0,
      "tsf_primary_eligibility" => false,
      "tsf_primary_plus_eligibility" => false,
      "works_in_childcare" => false,
      "works_in_nursery" => nil,
      "works_in_school" => false,
      "work_setting" => "another_setting",
      "senco_in_role" => nil,
      "senco_start_date" => nil,
      "on_submission_trn" => nil,
      "review_status" => nil,
      "raw_application_data" => {
        "can_share_choices" => "1",
        "check_funding" => "yes",
        "course_start_cohort" => course_start_cohort_value,
        "course_identifier" => "npq-leading-teaching",
        "employer_name" => "Big company",
        "employment_type" => "hospital_school",
        "funding" => "self",
        "declared_previous_funding" => "no",
        "email_template" => "not_eligible_scholarship_funding_not_tsf",
        "funding_eligiblity_status_code" => "ineligible_establishment_type",
        "institution_identifier" => "School-#{school.urn}",
        "institution_name" => "open",
        "lead_provider_id" => LeadProvider.find_by(name: "Teach First").id.to_s,
        "pre_login_funding_eligiblity_status_code" => "ineligible_establishment_type",
        "submitted" => true,
        "teacher_catchment" => "england",
        "teacher_catchment_country" => nil,
        "work_setting" => "another_setting",
        "works_in_childcare" => "no",
        "works_in_school" => "no",
      },
    )
  end
end
