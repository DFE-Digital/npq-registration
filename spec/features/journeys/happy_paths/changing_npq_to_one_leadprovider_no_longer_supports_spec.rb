require "rails_helper"

RSpec.feature "Happy journeys", type: :feature do
  include Helpers::JourneyHelper
  include Helpers::JourneyAssertionHelper
  include Helpers::JourneyStepHelper

  include_context "retrieve latest application data"
  include_context "Stub previously funding check for all courses" do
    let(:api_call_get_an_identity_id) { user_uid }
    let(:api_call_trn) { user_trn }
  end
  include_context "Enable Get An Identity integration"

  context "when JavaScript is enabled", :js do
    scenario("registration journey changing NPQ to one LeadProvider no longer supports (with JS)") { run_scenario(js: true) }
  end

  context "when JavaScript is disabled", :no_js do
    include_context "use rack_test driver"
    scenario("registration journey changing NPQ to one LeadProvider no longer supports (without JS)") { run_scenario(js: false) }
  end

  def run_scenario(js:)
    stub_participant_validation_request

    navigate_to_page(path: "/", submit_form: false, axe_check: false) do
      expect(page).to have_text("Before you start")
      page.click_link("Start now")
    end

    expect_page_to_have(path: "/registration/teacher-reference-number", submit_form: true) do
      page.choose("Yes", visible: :all)
    end

    unless js
      expect_page_to_have(path: "/registration/get-an-identity", submit_form: true)
    end

    expect(page).not_to have_content("Do you have a TRN?")

    expect_page_to_have(path: "/registration/provider-check", submit_form: true) do
      expect(page).to have_text("Have you already chosen an NPQ and provider?")
      page.choose("Yes", visible: :all)
    end

    # TODO: aria-expanded
    expect_page_to_have(path: "/registration/teacher-catchment", axe_check: false, submit_form: true) do
      page.choose("England", visible: :all)
    end

    expect_page_to_have(path: "/registration/work-setting", submit_form: true) do
      page.choose("Early years or childcare", visible: :all)
    end

    School.create!(urn: 100_000, name: "open manchester school", address_1: "street 1", town: "manchester", establishment_status_code: "1")

    public_kind_of_nursery_key = Forms::KindOfNursery::KIND_OF_NURSERY_PUBLIC_OPTIONS.sample
    public_kind_of_nursery = I18n.t(public_kind_of_nursery_key, scope: "helpers.label.registration_wizard.kind_of_nursery_options")

    expect_page_to_have(path: "/registration/kind-of-nursery", submit_form: true) do
      expect(page).to have_text("Which early years setting do you work in?")
      page.choose(public_kind_of_nursery, visible: :all)
    end

    expect_page_to_have(path: "/registration/find-childcare-provider", submit_form: true) do
      expect(page).to have_text("Where is your workplace located?")
      page.fill_in "Where is your workplace located?", with: "manchester"
    end

    choose_a_childcare_provider(js:, location: "manchester", name: "open")

    expect_page_to_have(path: "/registration/choose-your-npq", submit_form: true) do
      expect(page).to have_text("Which NPQ do you want to do?")
      page.choose("Senior leadership", visible: :all)
    end

    expect_page_to_have(path: "/registration/ineligible-for-funding", submit_form: false) do
      expect(page).to have_text("DfE scholarship funding is not available")
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
      page.choose "My workplace is covering the cost", visible: :all
    end

    expect_page_to_have(path: "/registration/choose-your-provider", submit_form: true) do
      expect(page).to have_text("Select your provider")
      page.choose("Best Practice Network (home of Outstanding Leaders Partnership)", visible: :all)
    end

    expect_page_to_have(path: "/registration/share-provider", submit_form: true) do
      expect(page).to have_text("Sharing your NPQ information")
      page.check("Yes, I agree my information can be shared", visible: :all)
    end

    expect_page_to_have(path: "/registration/check-answers", submit_form: false) do
      expect_check_answers_page_to_have_answers(
        {
          "Course" => "Senior leadership",
          "How is your NPQ being paid for?" => "My workplace is covering the cost",
          "Lead provider" => "Best Practice Network (home of Outstanding Leaders Partnership)",
          "What setting do you work in?" => "Early years or childcare",
          "Nursery" => "open manchester school",
          "Which early years setting do you work in?" => public_kind_of_nursery,
          "Where do you work?" => "England",
        },
      )

      page.click_link("Change", href: "/registration/choose-your-npq/change")
    end

    expect_page_to_have(path: "/registration/choose-your-npq/change", submit_form: true) do
      expect(page).to have_text("Which NPQ do you want to do?")
      page.choose("Early years leadership", visible: :all) # Needs changing to an early years course once added
    end

    expect_page_to_have(path: "/registration/ineligible-for-funding/change", submit_form: false) do
      expect(page).to have_text("DfE scholarship funding is not available")
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
      page.choose "My workplace is covering the cost", visible: :all
    end

    expect_page_to_have(path: "/registration/choose-your-provider", submit_form: true) do
      expect(page).to have_text("Select your provider")
      expect(page).to_not have_text("Best Practice Network (home of Outstanding Leaders Partnership)")
      page.choose("Teacher Development Trust", visible: :all)
    end

    expect_page_to_have(path: "/registration/share-provider", submit_form: true) do
      expect(page).to have_text("Sharing your NPQ information")
      page.check("Yes, I agree my information can be shared", visible: :all)
    end

    allow(ApplicationSubmissionJob).to receive(:perform_later).with(anything)

    expect_page_to_have(path: "/registration/check-answers", submit_button_text: "Submit", submit_form: true) do
      expect_check_answers_page_to_have_answers(
        {
          "Course" => "Early years leadership",
          "How is your NPQ being paid for?" => "My workplace is covering the cost",
          "Lead provider" => "Teacher Development Trust",
          "What setting do you work in?" => "Early years or childcare",
          "Nursery" => "open manchester school",
          "Which early years setting do you work in?" => public_kind_of_nursery,
          "Where do you work?" => "England",
        },
      )
    end

    expect_page_to_have(path: "/registration/confirmation", submit_form: false) do
      expect(page).to have_text("Your initial registration is complete")
    end

    expect(retrieve_latest_application_user_data).to eq(
      "active_alert" => nil,
      "admin" => false,
      "date_of_birth" => "1980-12-13",
      "ecf_id" => nil,
      "email" => "user@example.com",
      "flipper_admin_access" => false,
      "full_name" => "John Doe",
      "get_an_identity_id_synced_to_ecf" => false,
      "national_insurance_number" => nil,
      "otp_expires_at" => nil,
      "otp_hash" => nil,
      "provider" => "tra_openid_connect",
      "raw_tra_provider_data" => stubbed_callback_response_as_json,
      "trn" => "1234567",
      "trn_auto_verified" => false,
      "trn_verified" => true,
      "uid" => user_uid,
    )

    expect(retrieve_latest_application_data).to eq(
      "cohort" => 2022,
      "course_id" => Course.find_by(identifier: "npq-early-years-leadership").id,
      "ecf_id" => nil,
      "eligible_for_funding" => false,
      "employer_name" => nil,
      "employment_type" => nil,
      "employment_role" => nil,
      "funding_choice" => "school",
      "itt_provider" => nil,
      "lead_mentor" => false,
      "funding_eligiblity_status_code" => "ineligible_establishment_type",
      "headteacher_status" => nil,
      "kind_of_nursery" => public_kind_of_nursery_key,
      "lead_provider_id" => LeadProvider.find_by(name: "Teacher Development Trust").id,
      "private_childcare_provider_urn" => nil,
      "school_urn" => "100000",
      "targeted_delivery_funding_eligibility" => false,
      "teacher_catchment" => "england",
      "teacher_catchment_country" => nil,
      "teacher_catchment_synced_to_ecf" => false,
      "ukprn" => nil,
      "works_in_childcare" => true,
      "works_in_nursery" => nil,
      "works_in_school" => false,
      "work_setting" => "early_years_or_childcare",
      "raw_application_data" => {
        "can_share_choices" => "1",
        "chosen_provider" => "yes",
        "course_identifier" => "npq-early-years-leadership",
        "funding" => "school",
        "institution_identifier" => "School-100000",
        "institution_location" => "manchester",
        "institution_name" => js ? "" : "open",
        "kind_of_nursery" => public_kind_of_nursery_key,
        "lead_provider_id" => LeadProvider.find_by(name: "Teacher Development Trust").id.to_s,
        "teacher_catchment" => "england",
        "teacher_catchment_country" => nil,
        "trn_knowledge" => "yes",
        "works_in_childcare" => "yes",
        "works_in_school" => "no",
        "work_setting" => "early_years_or_childcare",
      },
    )
  end
end
