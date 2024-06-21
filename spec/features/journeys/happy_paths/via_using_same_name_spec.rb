require "rails_helper"

RSpec.feature "Happy journeys", type: :feature, rack_test_driver: true do
  include Helpers::JourneyAssertionHelper
  include Helpers::JourneyStepHelper
  include ApplicationHelper

  include_context "Stub Get An Identity Omniauth Responses"

  context "when JavaScript is enabled", :js do
    scenario("registration journey via using same name (with JS)") { run_scenario(js: true) }
  end

  context "when JavaScript is disabled", :no_js do
    scenario("registration journey via using same name (without JS)") { run_scenario(js: false) }
  end

  def run_scenario(js:)
    stub_participant_validation_request

    navigate_to_page(path: "/", submit_form: false, axe_check: false) do
      expect(page).to have_text("Before you start")
      page.click_button("Start now")
    end

    expect(page).not_to have_content("Before you start")

    expect_page_to_have(path: "/registration/course-start-date", submit_form: true) do
      expect(page).to have_text("NPQ start dates are usually every February and October.")
      page.choose("Yes", visible: :all)
    end

    expect_page_to_have(path: "/registration/provider-check", submit_form: true) do
      expect(page).to have_text("Have you chosen an NPQ and provider?")
      page.choose("Yes", visible: :all)
    end

    expect_page_to_have(path: "/registration/teacher-catchment", axe_check: false, submit_form: true) do
      page.choose("Yes", visible: :all)
    end

    expect_page_to_have(path: "/registration/referred-by-return-to-teaching-adviser", submit_form: true) do
      page.choose("No", visible: :all)
    end

    expect_page_to_have(path: "/registration/work-setting", submit_form: true) do
      page.choose("A school", visible: :all)
    end

    School.create!(urn: 100_000, name: "open manchester school", address_1: "street 1", town: "manchester", establishment_status_code: "1")
    School.create!(urn: 100_001, name: "closed manchester school", address_1: "street 2", town: "manchester", establishment_status_code: "2")
    School.create!(urn: 100_002, name: "open newcastle school", address_1: "street 3", town: "newcastle", establishment_status_code: "1")

    choose_a_school(js:, location: "manchester", name: "open")

    mock_previous_funding_api_request(
      course_identifier: "npq-headship",
      get_an_identity_id: user_uid,
      trn: "1234567",
      response: ecf_funding_lookup_response(previously_funded: false),
    )

    expect_page_to_have(path: "/registration/choose-your-npq", submit_form: true) do
      expect(page).to have_text("Which NPQ do you want to do?")
      page.choose("Headship", visible: :all)
    end

    expect_page_to_have(path: "/registration/ineligible-for-funding", submit_form: false) do
      expect(page).to have_text("Funding")
      expect(page).to have_text("not eligible for scholarship funding")
      expect(page).to have_text("such as state funded schools")
      expect(page).to have_text("This means that you would need to pay for the course another way")

      page.click_link("Continue")
    end

    expect_page_to_have(path: "/registration/funding-your-npq", submit_form: true) do
      expect(page).to have_text("How are you funding your course?")
      page.choose("My trust is paying", visible: :all)
    end

    expect_page_to_have(path: "/registration/choose-your-provider", submit_form: true) do
      expect(page).to have_text("Select your provider")
      page.choose("Teach First", visible: :all)
    end

    expect_page_to_have(path: "/registration/share-provider", submit_form: true) do
      expect(page).to have_text("Sharing your NPQ information")
      page.check("Yes, I agree to share my information", visible: :all)
    end

    allow(ApplicationSubmissionJob).to receive(:perform_later).with(anything)

    expect_page_to_have(path: "/registration/check-answers", submit_button_text: "Submit", submit_form: true) do
      expect_check_answers_page_to_have_answers(
        {
          "Course start" => "Before #{application_course_start_date}",
          "Workplace in England" => "Yes",
          "Work setting" => "A school",
          "Course" => "Headship",
          "Provider" => "Teach First",
          "Workplace" => "open manchester school – street 1, manchester",
          "Referred by return to teaching adviser" => "No",
          "Course funding" => "My trust is paying",
        },
      )
    end

    expect_applicant_reached_end_of_journey

    if User.last.applications.count == 1
      navigate_to_page(path: "/accounts/user_registrations/#{User.last.applications.last.id}", axe_check: false, submit_form: false) do
        expect(page).to have_text("Teach First")
        expect(page).to have_text("Headship")
      end
    else
      navigate_to_page(path: "/account", axe_check: false, submit_form: false) do
        expect(page).to have_text("Teach First")
        expect(page).to have_text("Headship")
      end
    end

    visit("/registration/check-answers")
    expect(page).to have_current_path("/")

    expect(retrieve_latest_application_user_data).to match(
      "active_alert" => false,
      "date_of_birth" => "1980-12-13",
      "ecf_id" => nil,
      "email" => "user@example.com",
      "full_name" => "John Doe",
      "get_an_identity_id_synced_to_ecf" => false,
      "national_insurance_number" => nil,
      "notify_user_for_future_reg" => false,
      "provider" => "tra_openid_connect",
      "raw_tra_provider_data" => stubbed_callback_response_as_json,
      "trn" => "1234567",
      "trn_auto_verified" => false,
      "trn_lookup_status" => "Found",
      "trn_verified" => true,
      "uid" => user_uid,
    )

    deep_compare_application_data(
      "cohort_id" => nil,
      "course_id" => Course.find_by(identifier: "npq-headship").id,
      "schedule_id" => nil,
      "ecf_id" => nil,
      "eligible_for_funding" => false,
      "employer_name" => nil,
      "employment_type" => nil,
      "employment_role" => nil,
      "funded_place" => nil,
      "funding_choice" => "trust",
      "funding_eligiblity_status_code" => "ineligible_establishment_type",
      "headteacher_status" => nil,
      "kind_of_nursery" => nil,
      "itt_provider_id" => nil,
      "lead_mentor" => false,
      "lead_provider_approval_status" => nil,
      "participant_outcome_state" => nil,
      "lead_provider_id" => LeadProvider.find_by(name: "Teach First").id,
      "notes" => nil,
      "private_childcare_provider_id" => nil,
      "referred_by_return_to_teaching_adviser" => "no",
      "school_id" => School.find_by(urn: "100000").id,
      "targeted_delivery_funding_eligibility" => false,
      "targeted_support_funding_eligibility" => false,
      "teacher_catchment" => "england",
      "teacher_catchment_country" => nil,
      "teacher_catchment_iso_country_code" => nil,
      "teacher_catchment_synced_to_ecf" => false,
      "training_status" => "active",
      "ukprn" => nil,
      "primary_establishment" => false,
      "number_of_pupils" => nil,
      "tsf_primary_eligibility" => false,
      "tsf_primary_plus_eligibility" => false,
      "works_in_childcare" => false,
      "works_in_nursery" => nil,
      "works_in_school" => true,
      "work_setting" => "a_school",
      "raw_application_data" => {
        "can_share_choices" => "1",
        "chosen_provider" => "yes",
        "course_start" => "Before #{application_course_start_date}",
        "course_start_date" => "yes",
        "course_identifier" => "npq-headship",
        "funding" => "trust",
        "funding_amount" => nil,
        "funding_eligiblity_status_code" => "ineligible_establishment_type",
        "email_template" => "not_eligible_scholarship_funding_not_tsf",
        "institution_identifier" => "School-100000",
        "institution_location" => "manchester",
        "institution_name" => js ? "" : "open",
        "lead_provider_id" => "9",
        "referred_by_return_to_teaching_adviser" => "no",
        "submitted" => true,
        "targeted_delivery_funding_eligibility" => false,
        "teacher_catchment" => "england",
        "teacher_catchment_country" => nil,
        "works_in_school" => "yes",
        "works_in_childcare" => "no",
        "tsf_primary_eligibility" => false,
        "tsf_primary_plus_eligibility" => false,
        "work_setting" => "a_school",
      },
    )
  end
end
