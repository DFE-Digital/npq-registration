require "rails_helper"

RSpec.feature "Happy journeys", :no_js, :with_cohorts, :with_default_school, type: :feature do
  include Helpers::JourneyAssertionHelper
  include Helpers::JourneyStepHelper
  include ApplicationHelper

  include_context "with stubbed Teacher Auth OmniAuth responses"
  include_context "with stubbed Teaching Record System person API"

  before do
    navigate_to_page(path: "/", submit_form: false) do
      page.click_button("Start now")
    end
  end

  scenario "Declared as previously funded" do
    choose_course_start_date

    expect_page_to_have(path: "/registration/check-funding", submit_form: true) do
      expect(page).to have_text("Check if you’re eligible for DfE scholarship funding")
      click_button("Check funding")
    end

    expect_page_to_have(path: "/registration/teacher-catchment", submit_form: true) do
      expect(page).to have_text("Do you work in England?")
      choose("Yes", visible: :all)
    end

    expect_page_to_have(path: "/registration/choose-your-npq", submit_form: true) do
      expect(page).to have_text("Choose an NPQ")
      page.choose("Headship", visible: :all)
    end

    expect_page_to_have(path: "/registration/funding-history", submit_form: true) do
      expect(page).to have_text("Have you received DfE funding for this course before?")
      page.choose("Yes", visible: :all)
    end

    expect_page_to_have(path: "/registration/ineligible-for-funding-previously-funded", submit_form: false) do
      expect(page).to have_text("You’re not eligible for DfE scholarship funding because you have received DfE funding for this course before.")
      page.click_link("Continue to register")
    end

    expect_page_to_have(path: "/registration/work-setting", submit_form: true) do
      page.choose("A school", visible: :all)
      page.choose("Primary school (5 to 11)", visible: :all)
    end

    choose_a_school(js: false, name: "open")

    expect_page_to_have(path: "/registration/funding-your-npq", submit_form: true) do
      page.choose "I am paying", visible: :all
    end

    choose_provider_share_information_and_check_answers(provider: "Teach First")

    check_back_journey_is_correct(exclude_current_page: true)

    check_answers_log_in_and_submit do
      expect_check_answers_page_to_have_answers(
        {
          "Cohort" => "Autumn 2026",
          "Course funding" => "I am paying",
          "Course" => "Headship",
          "DfE scholarship funding" => "Not eligible",
          "Provider" => "Teach First",
          "Workplace" => "open manchester school – street 1, manchester",
          "Work setting" => "Primary school (5 to 11)",
          "Working in England" => "Yes",
        },
      )
    end

    expect_applicant_reached_end_of_journey

    deep_compare_application_data(
      "accepted_at" => nil,
      "cohort_id" => Cohort.current.id,
      "course_id" => Course.find_by(identifier: "npq-headship").id,
      "schedule_id" => nil,
      "ecf_id" => latest_application.ecf_id,
      "eligible_for_funding" => false,
      "employer_name" => nil,
      "employment_type" => nil,
      "employment_role" => nil,
      "funded_place" => nil,
      "funding_choice" => "self",
      "funding_eligiblity_status_code" => "previously_funded",
      "kind_of_nursery" => nil,
      "headteacher_status" => nil,
      "itt_provider_id" => nil,
      "lead_mentor" => false,
      "lead_provider_approval_status" => "pending",
      "participant_outcome_state" => nil,
      "lead_provider_id" => LeadProvider.find_by(name: "Teach First").id,
      "notes" => nil,
      "private_childcare_provider_id" => nil,
      "referred_by_return_to_teaching_adviser" => nil,
      "school_id" => default_school.id,
      "targeted_delivery_funding_eligibility" => false,
      "targeted_support_funding_eligibility" => false,
      "teacher_catchment" => "england",
      "teacher_catchment_country" => "United Kingdom of Great Britain and Northern Ireland",
      "teacher_catchment_iso_country_code" => "GBR",
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
        "course_start_cohort" => "2026b",
        "course_identifier" => "npq-headship",
        "declared_previous_funding" => "yes",
        "email_template" => "already_funded_not_eligible_scholarship_funding_not_tsf",
        "funding" => "self",
        "funding_eligiblity_status_code" => "previously_funded",
        "institution_identifier" => "School-#{default_school.urn}",
        "institution_name" => "open",
        "lead_provider_id" => LeadProvider.find_by(name: "Teach First").id.to_s,
        "pre_login_funding_eligiblity_status_code" => "previously_funded",
        "previously_funded" => true,
        "submitted" => true,
        "teacher_catchment" => "england",
        "teacher_catchment_country" => nil,
        "work_setting" => "primary_school",
        "works_in_childcare" => "no",
        "works_in_school" => "yes",
      },
    )
  end

  scenario "Declared as not previously funded with unfunded cohort" do
    choose_course_start_date(first_option: false)

    expect_page_to_have(path: "/registration/choose-your-npq", submit_form: true) do
      expect(page).to have_text("Choose an NPQ")
      page.choose("Headship", visible: :all)
    end

    expect_page_to_have(path: "/registration/work-setting", submit_form: true) do
      page.choose("A school", visible: :all)
      page.choose("Primary school (5 to 11)", visible: :all)
    end

    choose_a_school(js: false, name: "open")

    expect_page_to_have(path: "/registration/ineligible-for-funding", submit_form: false) do
      expect(page).to have_content("You’re not eligible for scholarship funding for the Headship NPQ course as you have selected the Spring 2026 cohort.")
      page.click_link("Continue to register")
    end

    expect_page_to_have(path: "/registration/funding-your-npq", submit_form: true) do
      page.choose "I am paying", visible: :all
    end

    choose_provider_share_information_and_check_answers(provider: "LLSE") do
      expect(page).to have_content 'funding_eligiblity_status_code: "unfunded_cohort"'
    end

    check_back_journey_is_correct(exclude_current_page: true)
  end

  scenario "Declared as not previously funded with funded cohort" do
    choose_course_start_date

    expect_page_to_have(path: "/registration/check-funding", submit_form: true) do
      expect(page).to have_text("Check if you’re eligible for DfE scholarship funding")
      click_button("Check funding")
    end

    expect_page_to_have(path: "/registration/teacher-catchment", submit_form: true) do
      expect(page).to have_text("Do you work in England?")
      choose("Yes", visible: :all)
    end

    expect_page_to_have(path: "/registration/choose-your-npq", submit_form: true) do
      expect(page).to have_text("Choose an NPQ")
      page.choose("Headship", visible: :all)
    end

    expect_page_to_have(path: "/registration/funding-history", submit_form: true) do
      expect(page).to have_text("Have you received DfE funding for this course before?")
      page.choose("No", visible: :all)
    end

    expect_page_to_have(path: "/registration/work-setting", submit_form: true) do
      page.choose("A school", visible: :all)
      page.choose("Primary school (5 to 11)", visible: :all)
    end

    choose_a_school(js: false, name: "open")

    expect_page_to_have(path: "/registration/ineligible-for-funding", submit_form: false) do
      expect(page).to have_content("You’re not eligible for scholarship funding for the Headship NPQ course as you do not work in one of the eligible settings")
      page.click_link("Continue to register")
    end

    expect_page_to_have(path: "/registration/funding-your-npq", submit_form: true) do
      page.choose "I am paying", visible: :all
    end

    choose_provider_share_information_and_check_answers(provider: "Teach First") do
      expect(page).to have_content 'funding_eligiblity_status_code: "ineligible_establishment_type"'
    end

    check_back_journey_is_correct(exclude_current_page: true)
  end
end
