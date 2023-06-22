require "rails_helper"

RSpec.feature "Happy journeys", type: :feature do
  include Helpers::JourneyHelper
  include Helpers::JourneyAssertionHelper

  include_context "Stub previously funding check for all courses" do
    let(:api_call_trn) { user_trn }
  end
  include_context "Stub Get An Identity Omniauth Responses"

  around do |example|
    Capybara.current_driver = :rack_test

    example.run

    Capybara.current_driver = Capybara.default_driver
  end

  scenario "other funded EHCO registration journey" do
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

    expect_page_to_have(path: "/registration/teacher-catchment", axe_check: false, submit_form: true) do
      page.choose("England", visible: :all)
    end

    expect_page_to_have(path: "/registration/work-setting", submit_form: true) do
      page.choose("A school", visible: :all)
    end

    School.create!(urn: 100_000, name: "open manchester school", address_1: "street 1", town: "manchester", establishment_status_code: "1")
    School.create!(urn: 100_001, name: "closed manchester school", address_1: "street 2", town: "manchester", establishment_status_code: "2")
    School.create!(urn: 100_002, name: "open newcastle school", address_1: "street 3", town: "newcastle", establishment_status_code: "1")

    expect_page_to_have(path: "/registration/find-school", submit_form: true) do
      page.fill_in "Where is your workplace located?", with: "manchester"
    end

    expect_page_to_have(path: "/registration/choose-school", submit_form: true) do
      expect(page).to have_text("Search for your school or 16 to 19 educational setting in manchester. If you work for a trust, enter one of their schools.")

      within ".npq-js-hidden" do
        page.fill_in "What’s the name of your workplace?", with: "open"
      end

      page.click_button("Continue")

      expect(page).to have_text("Search for your school or 16 to 19 educational setting in manchester. If you work for a trust, enter one of their schools.")
      page.choose "open manchester school"
    end

    expect_page_to_have(path: "/registration/choose-your-npq", submit_form: true) do
      expect(page).to have_text("Which NPQ do you want to do?")
      page.choose("Early headship coaching offer")
    end

    expect_page_to_have(path: "/registration/npqh-status", submit_form: true) do
      expect(page).to have_selector "h1", text: "What stage are you at with the Headship NPQ?"
      page.choose "None of the above"
    end

    expect_page_to_have(path: "/registration/ehco-unavailable", submit_form: false) do
      expect(page).to have_selector "p", text: "Go back if you want to register for Headship NPQ"

      page.click_link("Back")
    end

    expect_page_to_have(path: "/registration/npqh-status", submit_form: true) do
      expect(page).to have_selector "h1", text: "What stage are you at with the Headship NPQ?"
      page.choose "I’ve completed it"
    end

    expect_page_to_have(path: "/registration/ehco-headteacher", submit_form: true) do
      expect(page).to have_text("Are you a headteacher?")
      page.choose("No", visible: :all)
    end

    expect_page_to_have(path: "/registration/ehco-funding-not-available", click_continue: true) do
      expect(page).to have_selector "p", text: "not eligible for the scholarship funding"
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
          "Where do you work?" => "England",
          "What setting do you work in?" => "A school",
          "Course" => "Early headship coaching offer",
          "Lead provider" => "Teach First",
          "Workplace" => "open manchester school",
          "Are you a headteacher?" => "No",
          "Have you completed an NPQH?" => "I’ve completed it",
          "How is your EHCO being paid for?" => "I am paying",
        },
      )
    end

    expect_page_to_have(path: "/registration/confirmation", submit_form: false) do
      expect(page).to have_text("You’ve registered for the Early headship coaching offer with Teach First")
      expect(page).not_to have_text("The Early headship coaching offer is a package of structured face-to-face support for new headteachers.")
    end

    expect(User.count).to be(1)
    expect(User.last.applications.count).to be(1)

    navigate_to_page(path: "/account", submit_form: false, axe_check: false) do
      expect(page).to have_text("Teach First")
      expect(page).to have_text("Early headship coaching offer")
    end

    visit "/registration/check-answers"
    expect(page).to have_current_path("/")

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
      "course_id" => Course.find_by(identifier: "npq-early-headship-coaching-offer").id,
      "ecf_id" => nil,
      "eligible_for_funding" => false,
      "employer_name" => nil,
      "employment_type" => nil,
      "employment_role" => nil,
      "funding_choice" => "self",
      "funding_eligiblity_status_code" => "ineligible_establishment_type",
      "headteacher_status" => "no",
      "kind_of_nursery" => nil,
      "lead_provider_id" => LeadProvider.find_by(name: "Teach First").id,
      "private_childcare_provider_urn" => nil,
      "school_urn" => "100000",
      "itt_provider" => nil,
      "lead_mentor" => false,
      "lead_provider_approval_status" => "pending",
      "state" => nil,
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
        "course_identifier" => "npq-early-headship-coaching-offer",
        "ehco_funding_choice" => "self",
        "ehco_headteacher" => "no",
        "email_template" => "not_eligible_ehco_funding",
        "funding_eligiblity_status_code" => "ineligible_establishment_type",
        "institution_identifier" => "School-100000",
        "institution_location" => "manchester",
        "institution_name" => "open",
        "lead_provider_id" => "9",
        "funding_amount" => nil,
        "npqh_status" => "completed_npqh",
        "targeted_delivery_funding_eligibility" => false,
        "teacher_catchment" => "england",
        "teacher_catchment_country" => nil,
        "works_in_school" => "yes",
        "tsf_primary_eligibility" => false,
        "tsf_primary_plus_eligibility" => false,
        "work_setting" => "a_school",
        "works_in_childcare" => "no",
      },
    )
  end
end
