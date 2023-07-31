require "rails_helper"

RSpec.feature "Happy journeys", type: :feature do
  include Helpers::JourneyHelper
  include Helpers::JourneyAssertionHelper
  include Helpers::JourneyStepHelper

  context "when JavaScript is enabled", :js do
    scenario("registration journey when previously funded (with JS)") { run_scenario(js: true) }
  end

  context "when JavaScript is disabled", :no_js do
    scenario("registration journey when previously funded (without JS)") { run_scenario(js: false) }
  end

  include_context "retrieve latest application data"
  include_context "Stub previously funding check for all courses" do
    let(:api_call_trn) { user_trn }
  end
  include_context "Stub Get An Identity Omniauth Responses"

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
      page.choose("Yes", visible: :all)
    end

    expect_page_to_have(path: "/registration/work-setting", submit_form: true) do
      page.choose("Early years or childcare", visible: :all)
    end

    School.create!(urn: 100_000, name: "open manchester school", address_1: "street 1", town: "manchester", establishment_status_code: "1")

    expect_page_to_have(path: "/registration/kind-of-nursery", submit_form: true) do
      expect(page).to have_text("Which early years setting do you work in?")
      page.choose("Private nursery", visible: :all)
    end

    expect_page_to_have(path: "/registration/have-ofsted-urn", submit_form: true) do
      expect(page).to have_text("Do you or your employer have an Ofsted unique reference number (URN)?")
      page.choose("Yes", visible: :all)
    end

    %w[npq-early-headship-coaching-offer npq-early-years-leadership].each do |identifier|
      mock_previous_funding_api_request(
        course_identifier: identifier,
        trn: "1234567",
        get_an_identity_id: user_uid,
        response: ecf_funding_lookup_response(previously_funded: true),
      )
    end

    choose_a_private_childcare_provider(js:, urn: "EY123456", name: "searchable childcare provider")

    expect_page_to_have(path: "/registration/choose-your-npq", submit_form: true) do
      expect(page).to have_text("Which NPQ do you want to do?")
      page.choose("Early years leadership", visible: :all)
    end

    expect_page_to_have(path: "/registration/ineligible-for-funding", submit_form: false) do
      expect(page).to have_text("Funding eligibility")
      expect(page).to have_text("already been allocated scholarship funding for")

      page.click_link("Back")
    end

    expect_page_to_have(path: "/registration/choose-your-npq", submit_form: true) do
      page.choose("Early headship coaching offer", visible: :all)
    end

    expect_page_to_have(path: "/registration/npqh-status", submit_form: true) do
      expect(page).to have_text("What stage are you at with the Headship NPQ?")
      page.choose("I’ve completed it", visible: :all)
    end

    expect_page_to_have(path: "/registration/ehco-headteacher", submit_form: true) do
      expect(page).to have_text("Are you a headteacher?")
      page.choose("Yes", visible: :all)
    end

    expect_page_to_have(path: "/registration/ehco-new-headteacher", submit_form: true) do
      expect(page).to have_text("Are you in your first 5 years of a headship?")
      page.choose("Yes", visible: :all)
    end

    expect_page_to_have(path: "/registration/ehco-previously-funded", submit_form: false) do
      expect(page).to have_text("Funding eligibility")
      expect(page).to have_text("You would need to pay for the EHCO if you were previously funded but you withdrew")

      page.click_link("Continue")
    end

    expect_page_to_have(path: "/registration/funding-your-ehco", submit_form: true) do
      expect(page).to have_text("How is the Early headship coaching offer being paid for?")
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
          "Course" => "Early headship coaching offer",
          "How is your EHCO being paid for?" => "I am paying",
          "Have you completed an NPQH?" => "I’ve completed it",
          "Are you a headteacher?" => "Yes",
          "Are you in your first 5 years of a headship?" => "Yes",
          "What setting do you work in?" => "Early years or childcare",
          "Lead provider" => "Teach First",
          "Ofsted registration details" => "EY123456 - searchable childcare provider",
          "Which early years setting do you work in?" => "Private nursery",
          "Do you work in England?" => "Yes",
        },
      )
    end

    expect_page_to_have(path: "/registration/confirmation", submit_form: false) do
      expect(page).to have_text("You’ve registered for the Early headship coaching offer with Teach First")
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
      "raw_tra_provider_data" => stubbed_callback_response_as_json,
      "provider" => "tra_openid_connect",
      "trn_auto_verified" => false,
      "trn_lookup_status" => "Found",
      "trn_verified" => true,
      "trn" => "1234567",
      "uid" => user_uid,
    )

    deep_compare_application_data(
      "course_id" => Course.find_by(identifier: "npq-early-headship-coaching-offer").id,
      "ecf_id" => nil,
      "eligible_for_funding" => false,
      "employer_name" => nil,
      "employment_type" => nil,
      "employment_role" => nil,
      "funding_choice" => "self",
      "itt_provider" => nil,
      "lead_mentor" => false,
      "lead_provider_approval_status" => nil,
      "participant_outcome_state" => nil,
      "funding_eligiblity_status_code" => "previously_funded",
      "headteacher_status" => "yes_in_first_five_years",
      "kind_of_nursery" => "private_nursery",
      "lead_provider_id" => LeadProvider.find_by(name: "Teach First").id,
      "private_childcare_provider_urn" => "EY123456",
      "school_urn" => nil,
      "targeted_delivery_funding_eligibility" => false,
      "teacher_catchment" => "england",
      "teacher_catchment_country" => nil,
      "teacher_catchment_synced_to_ecf" => false,
      "ukprn" => nil,
      "primary_establishment" => false,
      "number_of_pupils" => 0,
      "tsf_primary_eligibility" => false,
      "tsf_primary_plus_eligibility" => false,
      "works_in_childcare" => true,
      "works_in_nursery" => nil,
      "works_in_school" => false,
      "work_setting" => "early_years_or_childcare",
      "raw_application_data" => {
        "can_share_choices" => "1",
        "chosen_provider" => "yes",
        "course_identifier" => "npq-early-headship-coaching-offer",
        "email_template" => "already_funded_not_elgible_ehco_funding",
        "ehco_funding_choice" => "self",
        "ehco_headteacher" => "yes",
        "ehco_new_headteacher" => "yes",
        "funding_eligiblity_status_code" => "previously_funded",
        "funding_amount" => nil,
        "has_ofsted_urn" => "yes",
        "institution_identifier" => "PrivateChildcareProvider-EY123456",
        "institution_name" => js ? "" : "EY123456",
        "kind_of_nursery" => "private_nursery",
        "lead_provider_id" => LeadProvider.find_by(name: "Teach First").id.to_s,
        "npqh_status" => "completed_npqh",
        "targeted_delivery_funding_eligibility" => false,
        "teacher_catchment" => "england",
        "teacher_catchment_country" => nil,
        "tsf_primary_eligibility" => false,
        "tsf_primary_plus_eligibility" => false,
        "work_setting" => "early_years_or_childcare",
        "works_in_childcare" => "yes",
        "works_in_school" => "no",
      },
    )
  end
end
