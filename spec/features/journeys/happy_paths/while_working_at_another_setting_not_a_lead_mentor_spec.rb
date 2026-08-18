require "rails_helper"

RSpec.feature "Happy journeys", :no_js, :with_cohorts, :with_default_schedules, type: :feature do
  include Helpers::JourneyAssertionHelper
  include Helpers::JourneyStepHelper
  include ApplicationHelper

  include_context "retrieve latest application data"
  include_context "with stubbed Teacher Auth OmniAuth responses"
  include_context "with stubbed Teaching Record System person API"

  scenario "registration journey when choosing another setting but not as a lead mentor" do
    complete_journey_as_far_as_choosing_a_work_setting(
      course: "Senior leadership",
      work_setting: "Another setting",
    )

    expect_page_to_have(path: "/registration/your-employment", submit_form: true) do
      expect(page).to have_text("How are you employed?")
      page.choose("In an independent hospital education organisation", visible: :all)
    end

    expect_page_to_have(path: "/registration/your-employer", submit_form: true) do
      page.fill_in "What organisation are you employed by?", with: "Some company"
    end

    expect_page_to_have(path: "/registration/possible-funding", submit_form: true) do
      expect(page).to have_text("DfE scholarship funding")
      expect(page).to have_text("In review")
      expect(page).to have_text("Your registration will be reviewed by the Department for Education (DfE) to check if you’re eligible for scholarship funding.")
    end

    expect_page_to_have(path: "/registration/choose-your-provider", submit_form: true) do
      expect(page).to have_text("Select your provider")
      page.choose("Church of England", visible: :all)
    end

    expect_page_to_have(path: "/registration/share-provider", submit_form: true) do
      expect(page).to have_text("Sharing your NPQ information")
      page.check("Yes, I agree to share my information", visible: :all)
    end

    check_back_journey_is_correct

    check_answers_log_in_and_submit do
      expect_check_answers_page_to_have_answers(
        {
          "DfE scholarship funding" => "Not eligible",
          "Cohort" => course_start_cohort_description,
          "Course" => "Senior leadership",
          "Employment type" => "In an independent hospital education organisation",
          "Provider" => "Church of England",
          "Work setting" => "Another setting",
          "Working in England" => "Yes",
        },
      )
    end

    expect_applicant_reached_end_of_journey

    User.last.tap do |user|
      expect(user.email).to eql("user@example.com")
      expect(user.full_name).to eql("John Doe")
      expect(user.trn).to eql("1234567")
      expect(user.trn_verified).to be true
      expect(user.trn_auto_verified).to be true
      expect(user.national_insurance_number).to be_nil
      expect(user.applications.count).to be(1)

      user.applications.first.tap do |application|
        expect(application.eligible_for_funding).to be(false)
        expect(application.targeted_delivery_funding_eligibility).to be(false)
        expect(application.work_setting).to eql("another_setting")
        expect(application.raw_application_data["employment_type"])
          .to eql("hospital_school")
      end
    end

    navigate_to_page(path: "/accounts/user_registrations/#{User.last.applications.last.id}", axe_check: false, submit_form: false) do
      expect(page).to have_text("Your Senior leadership registration")
      expect(page).to have_text("Church of England")
      expect(page).to have_text("In review")
    end

    expect(retrieve_latest_application_user_data).to match(user_attributes_from_stubbed_callback_response)

    deep_compare_application_data(
      "accepted_at" => nil,
      "cohort_id" => Cohort.current.id,
      "course_id" => Course.find_by(identifier: "npq-senior-leadership").id,
      "schedule_id" => nil,
      "ecf_id" => latest_application.ecf_id,
      "eligible_for_funding" => false,
      "employer_name" => "Some company",
      "employment_type" => "hospital_school",
      "employment_role" => nil,
      "funded_place" => nil,
      "funding_choice" => nil,
      "funding_eligiblity_status_code" => "subject_to_review",
      "kind_of_nursery" => nil,
      "headteacher_status" => nil,
      "lead_provider_id" => LeadProvider.find_by(name: "Church of England").id,
      "notes" => nil,
      "private_childcare_provider_id" => nil,
      "referred_by_return_to_teaching_adviser" => nil,
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
      "lead_mentor" => false,
      "lead_provider_approval_status" => "pending",
      "participant_outcome_state" => nil,
      "senco_in_role" => nil,
      "senco_start_date" => nil,
      "on_submission_trn" => nil,
      "review_status" => "Needs review",
      "raw_application_data" => {
        "can_share_choices" => "1",
        "check_funding" => "yes",
        "course_identifier" => "npq-senior-leadership",
        "course_start_cohort" => course_start_cohort_value,
        "declared_previous_funding" => "no",
        "email_template" => "not_eligible_scholarship_funding_not_tsf",
        "employer_name" => "Some company",
        "employment_type" => "hospital_school",
        "funding_eligiblity_status_code" => "subject_to_review",
        "lead_provider_id" => LeadProvider.find_by(name: "Church of England").id.to_s,
        "pre_login_funding_eligiblity_status_code" => "subject_to_review",
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
