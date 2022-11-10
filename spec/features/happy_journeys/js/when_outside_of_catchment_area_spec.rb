require "rails_helper"

RSpec.feature "Happy journeys", type: :feature do
  include Helpers::JourneyHelper
  include Helpers::JourneyAssertionHelper

  include_context "retrieve latest application data"
  include_context "Enable Get An Identity integration"
  scenario "registration journey when outside of catchment area" do
    stub_participant_validation_request(nino: "")

    navigate_to_page(path: "/", submit_form: false, axe_check: false) do
      expect(page).to have_text("Before you start")
      page.click_link("Start now")
    end

    expect_page_to_have(path: "/registration/teacher-reference-number", submit_form: true) do
      page.choose("Yes", visible: :all)
    end

    expect(page).not_to have_content("Do you have a TRN?")

    expect_page_to_have(path: "/registration/provider-check", submit_form: true) do
      expect(page).to have_text("Have you already chosen an NPQ and provider?")
      page.choose("Yes", visible: :all)
    end

    # TODO: aria-expanded
    expect_page_to_have(path: "/registration/teacher-catchment", axe_check: false, submit_form: true) do
      page.choose("Another country", visible: :all)

      within "[data-module='app-country-autocomplete'" do
        page.fill_in "Which country do you teach in?", with: "Falk"
      end

      expect(page).to have_content("Falkland Islands")
      page.find("#registration-wizard-teacher-catchment-country-field__option--0").click
    end

    expect_page_to_have(path: "/registration/work-setting", submit_form: true) do
      page.choose("A school", visible: :all)
    end

    School.create!(urn: 100_000, name: "open manchester school", address_1: "street 1", town: "manchester", establishment_status_code: "1")

    expect_page_to_have(path: "/registration/choose-your-npq", submit_form: true) do
      expect(page).to have_text("What are you applying for?")
      page.choose("NPQ for Senior Leadership (NPQSL)", visible: :all)
    end

    expect_page_to_have(path: "/registration/ineligible-for-funding", submit_form: false) do
      expect(page).to have_text("DfE scholarship funding is not available")
      expect(page).to have_text("To be eligible for scholarship funding for")
      expect(page).to have_text("To be eligible for scholarship funding for")
      expect(page).to have_text("state-funded schools")
      expect(page).to have_text("state-funded 16 to 19 organisations")
      expect(page).to have_text("independent special schools")
      expect(page).to have_text("virtual schools")
      expect(page).to have_text("hospital schools")
      expect(page).to have_text("young offenders institutions")

      page.click_link("Continue")
    end

    expect_page_to_have(path: "/registration/funding-your-npq", submit_form: true) do
      expect(page).to have_text("How is your course being paid for?")
      page.choose "I am paying", visible: :all
    end

    expect_page_to_have(path: "/registration/choose-your-provider", submit_form: true) do
      expect(page).to have_text("Select your provider")
      page.choose("Teach First", visible: :all)
    end

    expect_page_to_have(path: "/registration/share-provider", submit_form: true) do
      expect(page).to have_text("Sharing your NPQ information")
      page.check("Yes, I agree my information can be shared", visible: :all)
    end

    allow(ApplicationSubmissionJob).to receive(:perform_later).with(anything)

    expect_page_to_have(path: "/registration/check-answers", submit_button_text: "Submit", submit_form: true) do
      expect_check_answers_page_to_have_answers(
        {

          "Course" => "NPQ for Senior Leadership (NPQSL)",
          "How is your NPQ being paid for?" => "I am paying",
          "What setting do you work in?" => "A school",
          "Lead provider" => "Teach First",
          "Where do you work?" => "Falkland Islands",
        },
      )
    end

    expect(retrieve_latest_application_user_data).to eq(
      "active_alert" => nil,
      "admin" => false,
      "date_of_birth" => "1980-12-13",
      "ecf_id" => nil,
      "email" => "user@example.com",
      "flipper_admin_access" => false,
      "full_name" => "John Doe",
      "national_insurance_number" => "AB123456C",
      "otp_expires_at" => nil,
      "otp_hash" => nil,
      "provider" => "tra_openid_connect",
      "raw_tra_provider_data" => stubbed_callback_response,
      "trn" => "1234567",
      "trn_auto_verified" => false,
      "trn_verified" => true,
      "uid" => user_uid,
    )

    expect(retrieve_latest_application_data).to eq(
      "cohort" => 2022,
      "course_id" => Course.find_by_code(code: :NPQSL).id,
      "ecf_id" => nil,
      "eligible_for_funding" => false,
      "employer_name" => nil,
      "employment_role" => nil,
      "employment_type" => nil,
      "funding_choice" => "self",
      "funding_eligiblity_status_code" => "no_institution",
      "headteacher_status" => nil,
      "kind_of_nursery" => nil,
      "lead_provider_id" => LeadProvider.find_by(name: "Teach First").id,
      "private_childcare_provider_urn" => nil,
      "school_urn" => nil,
      "targeted_delivery_funding_eligibility" => false,
      "targeted_support_funding_eligibility" => false,
      "teacher_catchment" => "another",
      "teacher_catchment_country" => "Falkland Islands",
      "teacher_catchment_synced_to_ecf" => false,
      "ukprn" => nil,
      "works_in_childcare" => false,
      "works_in_nursery" => false,
      "works_in_school" => true,
      "work_setting" => "a_school",
      "raw_application_data" => {
        "can_share_choices" => "1",
        "chosen_provider" => "yes",
        "course_id" => Course.find_by_code(code: :NPQSL).id.to_s,
        "funding" => "self",
        "lead_provider_id" => "9",
        "teacher_catchment" => "another",
        "teacher_catchment_country" => "Falkland Islands",
        "trn_knowledge" => "yes",
        "works_in_school" => "yes",
        "works_in_childcare" => "no",
        "work_setting" => "a_school",
      },
    )
  end
end
