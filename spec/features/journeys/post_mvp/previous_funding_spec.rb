require "rails_helper"

RSpec.feature "Previous funded application", :no_js, :with_cohorts, :with_default_schedules, type: :feature do
  include Helpers::JourneyAssertionHelper
  include Helpers::JourneyStepHelper
  include ApplicationHelper

  include_context "with stubbed Teacher Auth OmniAuth responses", stub: false
  include_context "with stubbed Teaching Record System person API", stub: false

  let(:school) { create(:school, :eligible_with_urn_and_address) }

  before do
    school
    user = create(:user, :with_verified_trn, email: user_email, trn: user_trn)
    create(:application, :accepted, :with_funded_place, user:, course: create(:course, :headship))
  end

  scenario "when not logged in - checks for previous applications after login" do
    complete_journey_as_far_as_choosing_a_work_setting(
      course: "Headship",
      work_setting: "Primary school (5 to 11)",
    )

    choose_a_school(js: false, name: "open")

    expect_page_to_have(path: "/registration/possible-funding", submit_form: false) do
      page.click_button "Continue to register"
    end

    expect_page_to_have(path: "/registration/choose-your-provider", submit_form: true) do
      page.choose("Teach First", visible: :all)
    end

    # check_back_journey_is_correct # FIXME: this currently fails

    expect_page_to_have(path: "/registration/share-provider", submit_form: true) do
      page.check("Yes, I agree to share my information", visible: :all)
    end

    expect_page_to_have(path: "/registration/check-answers", submit_form: true) do
      expect_check_answers_page_to_have_answers(
        {
          "Cohort" => "Autumn 2026",
          "Course" => "Headship",
          "DfE scholarship funding" => "Eligible",
          "Provider" => "Teach First",
          "Work setting" => "Primary school (5 to 11)",
          "Working in England" => "Yes",
          "Workplace" => "open manchester school – street 1, manchester",
        },
      )
    end

    stub_teacher_auth
    stub_trs

    expect_page_to_have(path: "/registration/continue-to-login", submit_form: true) do
      expect(page).to have_text("Continue through GOV.UK One Login")
    end

    expect_page_to_have(path: "/registration/check-answers-and-submit", submit_button_text: "Submit", submit_form: false) do
      expect_check_answers_page_to_have_answers(
        {
          "Cohort" => "Autumn 2026",
          "Course" => "Headship",
          "DfE scholarship funding" => "Not eligible",
          "Provider" => "Teach First",
          "Work setting" => "Primary school (5 to 11)",
          "Working in England" => "Yes",
          "Workplace" => "open manchester school – street 1, manchester",
        },
      )
    end

    expect(page).to have_text("Our records show that you have previously received funding for this course. " \
                              "This means you are not eligible for further funding.")

    page.click_button "Submit"

    expect_applicant_reached_end_of_journey(total_number_of_created_applications: 2)

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
      "funding_choice" => nil,
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
      "school_id" => school.id,
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
        "declared_previous_funding" => "no",
        "email_template" => "already_funded_not_eligible_scholarship_funding_not_tsf",
        "funding_eligiblity_status_code" => "previously_funded",
        "institution_identifier" => "School-#{school.urn}",
        "institution_name" => "open",
        "lead_provider_id" => LeadProvider.find_by(name: "Teach First").id.to_s,
        "pre_login_funding_eligiblity_status_code" => "funded",
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
end
