require "rails_helper"

RSpec.feature "Happy journeys", type: :feature do
  include Helpers::JourneyAssertionHelper
  include Helpers::JourneyStepHelper

  include_context "retrieve latest application data"
  include_context "Stub previously funding check for all courses" do
    let(:api_call_trn) { user_trn }
  end
  include_context "Stub Get An Identity Omniauth Responses"

  context "when JavaScript is enabled", :js do
    scenario("registration journey when choosing Leading primary mathematics journey (with JS)") { run_scenario(js: true) }
  end

  def run_scenario(*)
    stub_participant_validation_request

    navigate_to_page(path: "/", submit_form: false, axe_check: false) do
      expect(page).to have_text("Before you start")
      page.click_button("Start now")
    end

    expect(page).not_to have_content("Before you start")

    expect_page_to_have(path: "/registration/provider-check", submit_form: true) do
      expect(page).to have_text("Have you chosen an NPQ and provider?")
      page.choose("Yes", visible: :all)
    end

    expect_page_to_have(path: "/registration/teacher-catchment", axe_check: false, submit_form: true) do
      page.choose("Yes", visible: :all)
    end

    expect_page_to_have(path: "/registration/work-setting", submit_form: true) do
      page.choose("A school", visible: :all)
    end

    School.create!(urn: 100_000,
                   name: "open manchester school",
                   address_1: "street 1", town: "manchester",
                   establishment_status_code: "1",
                   establishment_type_code: 1,
                   number_of_pupils: 150,
                   phase_name: "Primary")
    School.create!(urn: 100_001, name: "closed manchester school", address_1: "street 2", town: "manchester", establishment_status_code: "2")
    School.create!(urn: 100_002, name: "open newcastle school", address_1: "street 3", town: "newcastle", establishment_status_code: "1")

    expect_page_to_have(path: "/registration/find-school", submit_form: true) do
      page.fill_in "Where is your workplace located?", with: "manchester"
    end

    expect_page_to_have(path: "/registration/choose-school", submit_form: true) do
      expect(page).to have_text("Search for your school or 16 to 19 educational setting in manchester. If you work for a trust, enter one of their schools.")

      within ".npq-js-reveal" do
        page.fill_in "What’s the name of your workplace?", with: "open"
      end

      expect(page).to have_content("open manchester school")

      page.find("#school-picker__option--0").click
      page.click_button("Continue")
    end

    mock_previous_funding_api_request(
      course_identifier: "npq-leading-primary-mathematics",
      response: ecf_funding_lookup_response(previously_funded: false),
      trn: "1234567",
      get_an_identity_id: User.last.get_an_identity_id,
    )

    expect_page_to_have(path: "/registration/choose-your-npq", submit_form: true) do
      expect(page).to have_text("Which NPQ do you want to do?")
      page.choose("Leading primary mathematics", visible: :all)
    end

    expect_page_to_have(path: "/registration/maths-eligibility-teaching-for-mastery", submit_form: true) do
      expect(page).to have_text("Have you taken at least one year of the primary maths Teaching for Mastery programme?")
      page.choose("Yes", visible: :all)
    end

    expect_page_to_have(path: "/registration/funding-eligibility-maths", submit_form: true) do
      expect(page).to have_text("Funding")
      expect(page).to have_text("If your provider accepts your application, you’ll be eligible for scholarship funding for the the Leading primary mathematics NPQ.")
    end

    expect_page_to_have(path: "/registration/choose-your-provider", submit_form: true) do
      expect(page).to have_text("Select your provider")
      page.choose("Church of England", visible: :all)
    end

    expect_page_to_have(path: "/registration/share-provider", submit_form: true) do
      expect(page).to have_text("Sharing your NPQ information")
      page.check("Yes, I agree my information can be shared", visible: :all)
    end

    allow(ApplicationSubmissionJob).to receive(:perform_later).with(anything)

    expect_page_to_have(path: "/registration/check-answers", submit_button_text: "Submit", submit_form: true) do
      expect_check_answers_page_to_have_answers(
        {
          "Workplace in England" => "Yes",
          "Work setting" => "A school",
          "Workplace" => "open manchester school – street 1, manchester",
          "Course" => "Leading primary mathematics",
          "Completed one year of the primary maths Teaching for Mastery programme" => "Yes",
          "Provider" => "Church of England",
        },
      )
    end

    expect_page_to_have(path: "/accounts/user_registrations/#{Application.last.id}?success=true", submit_form: false) do
      expect(page).to have_text("Registration successfully submitted")
      expect(page).to have_text("Leading primary mathematics NPQ")
    end

    expect(User.count).to be(1)

    User.last.tap do |user|
      expect(user.email).to eql("user@example.com")
      expect(user.full_name).to eql("John Doe")
      expect(user.trn).to eql("1234567")
      expect(user.trn_verified).to be_truthy
      expect(user.trn_auto_verified).to be_falsey
      expect(user.date_of_birth).to eql(Date.new(1980, 12, 13))
      expect(user.national_insurance_number).to eq(nil)
      expect(user.applications.count).to be(1)

      user.applications.first.tap do |application|
        expect(application.eligible_for_funding).to eq(true)
      end
    end

    expect(page).to have_text("Church of England")
    expect(page).to have_text("Leading primary mathematics NPQ")

    visit "/registration/share-provider"

    expect_page_to_have(path: "/", axe_check: false, submit_form: false) do
      expect(page).to have_content("Before you start")
    end

    expect(retrieve_latest_application_user_data).to match(
      "active_alert" => false,
      "admin" => false,
      "date_of_birth" => "1980-12-13",
      "ecf_id" => nil,
      "email" => "user@example.com",
      "full_name" => "John Doe",
      "get_an_identity_id_synced_to_ecf" => false,
      "national_insurance_number" => nil,
      "otp_expires_at" => nil,
      "otp_hash" => nil,
      "provider" => "tra_openid_connect",
      "raw_tra_provider_data" => stubbed_callback_response_as_json,
      "super_admin" => false,
      "trn" => "1234567",
      "trn_auto_verified" => false,
      "trn_lookup_status" => "Found",
      "trn_verified" => true,
      "uid" => user_uid,
    )

    deep_compare_application_data(
      "course_id" => Course.find_by(identifier: "npq-leading-primary-mathematics").id,
      "ecf_id" => nil,
      "eligible_for_funding" => true,
      "employer_name" => nil,
      "employment_type" => nil,
      "employment_role" => nil,
      "funding_choice" => nil,
      "funding_eligiblity_status_code" => "funded",
      "kind_of_nursery" => nil,
      "headteacher_status" => nil,
      "itt_provider_id" => nil,
      "lead_mentor" => false,
      "lead_provider_approval_status" => nil,
      "participant_outcome_state" => nil,
      "lead_provider_id" => LeadProvider.find_by(name: "Church of England").id,
      "private_childcare_provider_id" => nil,
      "school_id" => School.find_by(urn: "100000").id,
      "targeted_delivery_funding_eligibility" => true,
      "teacher_catchment" => "england",
      "teacher_catchment_country" => nil,
      "teacher_catchment_synced_to_ecf" => false,
      "ukprn" => nil,
      "primary_establishment" => true,
      "number_of_pupils" => 150,
      "tsf_primary_eligibility" => true,
      "tsf_primary_plus_eligibility" => true,
      "works_in_childcare" => false,
      "works_in_nursery" => nil,
      "works_in_school" => true,
      "work_setting" => "a_school",
      "raw_application_data" => {
        "can_share_choices" => "1",
        "chosen_provider" => "yes",
        "course_identifier" => "npq-leading-primary-mathematics",
        "email_template" => "eligible_scholarship_funding",
        "funding_eligiblity_status_code" => "funded",
        "institution_identifier" => "School-100000",
        "institution_location" => "manchester",
        "institution_name" => "",
        "lead_provider_id" => "3",
        "maths_eligibility_teaching_for_mastery" => "yes",
        "maths_understanding" => true,
        "submitted" => true,
        "targeted_delivery_funding_eligibility" => true,
        "teacher_catchment" => "england",
        "teacher_catchment_country" => nil,
        "works_in_school" => "yes",
        "works_in_childcare" => "no",
        "funding_amount" => 800,
        "tsf_primary_eligibility" => true,
        "tsf_primary_plus_eligibility" => true,
        "work_setting" => "a_school",
      },
    )
  end
end
