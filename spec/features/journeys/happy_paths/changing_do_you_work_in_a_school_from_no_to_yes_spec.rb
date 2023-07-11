require "rails_helper"

RSpec.feature "Happy journeys", type: :feature do
  include Helpers::JourneyHelper
  include Helpers::JourneyAssertionHelper
  include Helpers::JourneyStepHelper

  include_context "retrieve latest application data"
  include_context "Stub Get An Identity Omniauth Responses"

  context "when JavaScript is enabled", :js do
    scenario("registration journey changing do you work in a school from no to yes (with JS)") { run_scenario(js: true) }
  end

  context "when JavaScript is disabled", :no_js do
    scenario("registration journey changing do you work in a school from no to yes (without JS)") { run_scenario(js: false) }
  end

  def run_scenario(js:)
    stub_participant_validation_request

    navigate_to_page(path: "/", submit_form: false, axe_check: false) do
      expect(page).to have_text("Before you start")
      page.click_button("Start now")
    end

    expect(page).not_to have_content("Before you start")

    expect_page_to_have(path: "/registration/provider-check", submit_form: true) do
      expect(page).to have_text("Have you already chosen an NPQ and provider?")
      page.choose("Yes", visible: :all)
    end

    # TODO: aria-expanded
    expect_page_to_have(path: "/registration/teacher-catchment", axe_check: false, submit_form: true) do
      page.choose("England", visible: :all)
    end

    expect_page_to_have(path: "/registration/work-setting", submit_form: true) do
      page.choose("Other", visible: :all)
    end

    School.create!(urn: 100_000, name: "open manchester school", address_1: "street 1", town: "manchester", establishment_status_code: "1")

    expect_page_to_have(path: "/registration/your-employment", submit_form: true) do
      expect(page).to have_text("How are you employed?")
      page.choose("In a hospital school", visible: :all)
    end

    expect_page_to_have(path: "/registration/your-role", submit_form: true) do
      page.fill_in "What is your role?", with: "Trainer"
    end

    expect_page_to_have(path: "/registration/your-employer", submit_form: true) do
      page.fill_in "What organisation are you employed by?", with: "Big company"
    end

    expect_page_to_have(path: "/registration/choose-your-npq", submit_form: true) do
      expect(page).to have_text("Which NPQ do you want to do?")
      page.choose("Senior leadership", visible: :all)
    end

    expect_page_to_have(path: "/registration/choose-your-provider", submit_form: true) do
      expect(page).to have_text("Select your provider")
      page.choose("Teach First", visible: :all)
    end

    expect_page_to_have(path: "/registration/share-provider", submit_form: true) do
      expect(page).to have_text("Sharing your NPQ information")
      page.check("Yes, I agree my information can be shared", visible: :all)
    end

    expect_page_to_have(path: "/registration/check-answers", submit_form: false) do
      expect_check_answers_page_to_have_answers(
        {
          "Course" => "Senior leadership",
          "What setting do you work in?" => "Other",
          "Employment type" => "In a hospital school",
          "Employer" => "Big company",
          "Lead provider" => "Teach First",
          "Role" => "Trainer",
          "Where do you work?" => "England",
        },
      )

      page.click_link("Change", href: "/registration/work-setting/change")
    end

    expect_page_to_have(path: "/registration/work-setting/change", submit_form: true) do
      page.choose("A school", visible: :all)
    end

    mock_previous_funding_api_request(
      course_identifier: "npq-senior-leadership",
      get_an_identity_id: user_uid,
      trn: "1234567",
      response: ecf_funding_lookup_response(previously_funded: false),
    )

    choose_a_school(js:, location: "manchester", name: "open")

    expect_page_to_have(path: "/registration/choose-your-npq", submit_form: true) do
      expect(page).to have_text("Which NPQ do you want to do?")
      page.choose("Senior leadership", visible: :all)
    end

    expect_page_to_have(path: "/registration/ineligible-for-funding", submit_form: false) do
      expect(page).to have_text("Funding eligibility")
      expect(page).to have_text("such as state funded schools")
      expect(page).to have_text("You’re not eligible for scholarship funding")

      page.click_link("Continue")
    end

    expect_page_to_have(path: "/registration/funding-your-npq", submit_form: true) do
      expect(page).to have_text("How is your course being paid for?")
      page.choose "My workplace is covering the cost", visible: :all
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

    expect_page_to_have(path: "/registration/check-answers", submit_form: true, submit_button_text: "Submit") do
      expect_check_answers_page_to_have_answers(
        {
          "Course" => "Senior leadership",
          "How is your NPQ being paid for?" => "My workplace is covering the cost",
          "What setting do you work in?" => "A school",
          "Workplace" => "open manchester school",
          "Lead provider" => "Teach First",
          "Where do you work?" => "England",
        },
      )
    end

    expect_page_to_have(path: "/registration/confirmation", submit_form: false) do
      expect(page).to have_text("You’ve registered for the Senior leadership NPQ with Teach First")
      expect(page).not_to have_text("The Early headship coaching offer is a package of structured face-to-face support for new headteachers.")
    end

    expect(retrieve_latest_application_user_data).to match(
      "active_alert" => false,
      "admin" => false,
      "date_of_birth" => "1980-12-13",
      "ecf_id" => nil,
      "email" => "user@example.com",
      "super_admin" => false,
      "full_name" => "John Doe",
      "get_an_identity_id_synced_to_ecf" => false,
      "national_insurance_number" => nil,
      "otp_expires_at" => nil,
      "otp_hash" => nil,
      "provider" => "tra_openid_connect",
      "raw_tra_provider_data" => stubbed_callback_response_as_json,
      "trn" => "1234567",
      "trn_auto_verified" => false,
      "trn_lookup_status" => "Found",
      "trn_verified" => true,
      "uid" => user_uid,
    )

    deep_compare_application_data(
      "course_id" => Course.find_by(identifier: "npq-senior-leadership").id,
      "ecf_id" => nil,
      "eligible_for_funding" => false,
      "employer_name" => nil,
      "employment_type" => nil,
      "employment_role" => nil,
      "funding_choice" => "school",
      "funding_eligiblity_status_code" => "ineligible_establishment_type",
      "headteacher_status" => nil,
      "kind_of_nursery" => nil,
      "itt_provider" => nil,
      "lead_mentor" => false,
      "lead_provider_approval_status" => nil,
      "participant_outcome_state" => nil,
      "lead_provider_id" => LeadProvider.find_by(name: "Teach First").id,
      "private_childcare_provider_urn" => nil,
      "school_urn" => "100000",
      "targeted_delivery_funding_eligibility" => false,
      "teacher_catchment" => "england",
      "teacher_catchment_country" => nil,
      "teacher_catchment_synced_to_ecf" => false,
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
        "course_identifier" => "npq-senior-leadership",
        "employer_name" => "Big company",
        "employment_role" => "Trainer",
        "employment_type" => "hospital_school",
        "email_template" => "not_eligible_scholarship_funding_not_tsf",
        "funding" => "school",
        "funding_amount" => nil,
        "funding_eligiblity_status_code" => "ineligible_establishment_type",
        "institution_identifier" => "School-100000",
        "institution_location" => "manchester",
        "institution_name" => js ? "" : "open",
        "lead_provider_id" => LeadProvider.find_by(name: "Teach First").id.to_s,
        "targeted_delivery_funding_eligibility" => false,
        "teacher_catchment" => "england",
        "teacher_catchment_country" => nil,
        "tsf_primary_eligibility" => false,
        "tsf_primary_plus_eligibility" => false,
        "work_setting" => "a_school",
        "works_in_childcare" => "no",
        "works_in_school" => "yes",
      },
    )
  end
end
