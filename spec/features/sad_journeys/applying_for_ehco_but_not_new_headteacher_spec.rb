require "rails_helper"

RSpec.feature "Happy journeys", type: :feature do
  include Helpers::JourneyHelper
  include Helpers::JourneyAssertionHelper

  include_context "retrieve latest application data"
  include_context "Stub previously funding check for all courses" do
    let(:api_call_get_an_identity_id) { user_uid }
    let(:api_call_trn) { user_trn }
  end
  include_context "Enable Get An Identity integration"

  scenario "applying for EHCO but not new headteacher" do
    stub_participant_validation_request

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

    # expect(page).to be_axe_clean
    # TODO: aria-expanded
    expect_page_to_have(path: "/registration/teacher-catchment", axe_check: false, submit_form: true) do
      page.choose("England", visible: :all)
    end

    expect_page_to_have(path: "/registration/work-setting", submit_form: true) do
      page.choose("A school", visible: :all)
    end

    School.create!(urn: 100_000, name: "open manchester school", address_1: "street 1", town: "manchester", establishment_status_code: "1")

    expect_page_to_have(path: "/registration/find-school", submit_form: true) do
      page.fill_in "Where is your workplace located?", with: "manchester"
    end

    expect_page_to_have(path: "/registration/choose-school", submit_form: true) do
      expect(page).to have_text("Search for schools or 16 to 19 educational settings located in manchester. If you work for a trust, enter one of their schools.")

      within ".npq-js-reveal" do
        page.fill_in "What’s the name of your workplace?", with: "open"
      end

      expect(page).to have_content("open manchester school")

      page.find("#school-picker__option--0").click
      page.click_button("Continue")
    end

    expect_page_to_have(path: "/registration/choose-your-npq", submit_form: true) do
      expect(page).to have_text("Which NPQ do you want to do?")
      page.choose("Early headship coaching offer", visible: :all)
    end

    expect_page_to_have(path: "/registration/npqh-status", submit_form: true) do
      expect(page).to have_selector "h1", text: "What stage are you at with the headship NPQ?"

      page.choose "None of the above", visible: :all
    end

    expect_page_to_have(path: "/registration/aso-unavailable", submit_form: false) do
      expect(page).to have_selector "h1", text: "You cannot register for the Early Headship Coaching Offer"

      page.click_link("Back")
    end

    expect_page_to_have(path: "/registration/npqh-status", submit_form: true) do
      expect(page).to have_selector "h1", text: "What stage are you at with the headship NPQ?"

      page.choose "I've completed it", visible: :all
    end

    expect_page_to_have(path: "/registration/aso-headteacher", submit_form: true) do
      expect(page).to have_text("Are you a headteacher?")
      page.choose("Yes", visible: :all)
    end

    expect_page_to_have(path: "/registration/aso-new-headteacher", submit_form: true) do
      expect(page).to have_text("Are you in your first 5 years of a headship?")
      page.choose "No", visible: :all
    end

    expect_page_to_have(path: "/registration/aso-funding-not-available", click_continue: true) do
      expect(page).to have_selector "h1", text: "DfE scholarship funding is not available"
    end

    expect_page_to_have(path: "/registration/funding-your-aso", submit_form: true) do
      expect(page).to have_text("How is the Early Headship Coaching Offer being paid for?")
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
          "Where do you work?" => "England",
          "What setting do you work in?" => "A school",
          "Course" => "Early headship coaching offer",
          "Lead provider" => "Teach First",
          "How is your EHCO being paid for?" => "I am paying",
          "Workplace" => "open manchester school",
          "Are you a headteacher?" => "Yes",
          "Are you in your first 5 years of a headship?" => "No",
          "Have you completed an NPQH?" => "I've completed it",
        },
      )
    end

    expect_page_to_have(path: "/registration/confirmation", submit_form: false) do
      expect(page).to have_text("Your initial registration is complete")
      expect(page).not_to have_text("The Early Headship Coaching Offer is a package of structured face-to-face support for new headteachers.")
    end

    expect(retrieve_latest_application_user_data).to match(
      "active_alert" => nil,
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

    expect(retrieve_latest_application_data).to match(
      "course_id" => Course.find_by(identifier: "npq-early-headship-coaching-offer").id,
      "ecf_id" => nil,
      "eligible_for_funding" => false,
      "employer_name" => nil,
      "employment_type" => nil,
      "employment_role" => nil,
      "funding_choice" => "self",
      "itt_provider" => nil,
      "lead_mentor" => false,
      "funding_eligiblity_status_code" => "ineligible_establishment_type",
      "headteacher_status" => "yes_over_five_years",
      "kind_of_nursery" => nil,
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
      "works_in_nursery" => nil,
      "works_in_childcare" => false,
      "works_in_school" => true,
      "work_setting" => "a_school",
      "raw_application_data" => {
        "aso_funding_choice" => "self",
        "aso_headteacher" => "yes",
        "aso_new_headteacher" => "no",
        "can_share_choices" => "1",
        "chosen_provider" => "yes",
        "course_identifier" => "npq-early-headship-coaching-offer",
        "institution_identifier" => "School-100000",
        "institution_location" => "manchester",
        "institution_name" => "",
        "lead_provider_id" => "9",
        "npqh_status" => "completed_npqh",
        "teacher_catchment" => "england",
        "teacher_catchment_country" => nil,
        "trn_knowledge" => "yes",
        "works_in_school" => "yes",
        "works_in_childcare" => "no",
        "work_setting" => "a_school",
      },
    )
  end
end
