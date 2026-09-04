require "rails_helper"

RSpec.feature "Happy journeys", :no_js, :with_cohorts, :with_default_schedules, :with_eligibility_list_entries, type: :feature do
  include Helpers::JourneyAssertionHelper
  include Helpers::JourneyStepHelper
  include ApplicationHelper

  include_context "retrieve latest application data"
  include_context "with stubbed Teacher Auth OmniAuth responses"
  include_context "with stubbed Teaching Record System person API"

  let(:school) do
    School.create!(urn: 100_000,
                   name: "open manchester school",
                   address_1: "street 1", town: "manchester",
                   establishment_status_code: "1",
                   establishment_type_code: 1,
                   number_of_pupils: 150,
                   phase_name: "Primary")
  end

  before { school }

  scenario "registration journey when choosing Leading primary mathematics journey" do
    complete_journey_as_far_as_choosing_a_work_setting(
      course: "Leading primary mathematics",
      work_setting: "Primary school (5 to 11)",
    )

    choose_a_school(js: false, name: "open")

    expect_page_to_have(path: "/registration/maths-eligibility-teaching-for-mastery", submit_form: true) do
      expect(page).to have_text("Have you taken at least one year of the primary maths Teaching for Mastery programme?")
      page.choose("Yes", visible: :all)
    end

    expect_page_to_have(path: "/registration/funding-eligibility-maths", submit_form: true) do
      expect(page).to have_text("DfE scholarship funding")
      expect(page).to have_text("You’re eligible for scholarship funding for the Leading primary mathematics NPQ, but this does not guarantee a funded place is available.")
    end

    expect_page_to_have(path: "/registration/choose-your-provider", submit_form: true) do
      expect(page).to have_text("Select your provider")
      page.choose("Church of England", visible: :all)
    end

    expect_page_to_have(path: "/registration/share-provider", submit_form: true) do
      expect(page).to have_text("Sharing your NPQ information")
      page.check("Yes, I agree to share my information", visible: :all)
    end

    check_answers_log_in_and_submit do
      expect_check_answers_page_to_have_answers(
        {
          "DfE scholarship funding" => "Eligible",
          "Cohort" => course_start_cohort_description,
          "Working in England" => "Yes",
          "Work setting" => "Primary school (5 to 11)",
          "Workplace" => "open manchester school – street 1, manchester",
          "Course" => "Leading primary mathematics",
          "Completed one year of the primary maths Teaching for Mastery programme" => "Yes",
          "Provider" => "Church of England",
        },
      )
    end

    expect_page_to_have(path: "/accounts/user_registrations/#{latest_application.id}/registration-complete", submit_form: false) do
      expect(page).to have_text("Registration complete")
      page.click_link("Review a summary of your registration")
    end

    expect_page_to_have(path: "/accounts/user_registrations/#{latest_application.id}", submit_form: false) do
      expect(page).to have_text("Your Leading primary mathematics registration")
    end

    expect(User.count).to be(1)

    User.last.tap do |user|
      expect(user.email).to eql("user@example.com")
      expect(user.full_name).to eql("John Doe")
      expect(user.trn).to eql("1234567")
      expect(user.trn_verified).to be true
      expect(user.trn_auto_verified).to be true
      expect(user.national_insurance_number).to be_nil
      expect(user.applications.count).to be(1)

      user.applications.first.tap do |application|
        expect(application.eligible_for_funding).to be(true)
      end
    end

    expect(page).to have_text("Church of England")
    expect(page).to have_text("Your Leading primary mathematics registration")

    visit "/registration/share-provider"

    expect_page_to_have(path: "/", axe_check: false, submit_form: false) do
      expect(page).to have_content("Before you start")
    end

    expect(retrieve_latest_application_user_data).to match(user_attributes_from_stubbed_callback_response)

    deep_compare_application_data(
      "accepted_at" => nil,
      "cohort_id" => Cohort.current.id,
      "course_id" => Course.find_by(identifier: "npq-leading-primary-mathematics").id,
      "schedule_id" => nil,
      "ecf_id" => latest_application.ecf_id,
      "eligible_for_funding" => true,
      "employer_name" => nil,
      "employment_type" => nil,
      "employment_role" => nil,
      "funded_place" => nil,
      "funding_choice" => nil,
      "funding_eligiblity_status_code" => "funded",
      "kind_of_nursery" => nil,
      "headteacher_status" => nil,
      "itt_provider_id" => nil,
      "lead_mentor" => false,
      "lead_provider_approval_status" => "pending",
      "participant_outcome_state" => nil,
      "lead_provider_id" => LeadProvider.find_by(name: "Church of England").id,
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
      "primary_establishment" => true,
      "number_of_pupils" => 150,
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
        "course_identifier" => "npq-leading-primary-mathematics",
        "declared_previous_funding" => "no",
        "email_template" => "eligible_scholarship_funding_not_tsf",
        "funding_eligiblity_status_code" => "funded",
        "institution_identifier" => "School-#{school.urn}",
        "institution_name" => "open",
        "lead_provider_id" => LeadProvider.find_by(name: "Church of England").id.to_s,
        "pre_login_funding_eligiblity_status_code" => "funded",
        "maths_eligibility_teaching_for_mastery" => "yes",
        "maths_understanding" => true,
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
