require "rails_helper"

RSpec.feature "Happy journeys", type: :feature do
  include Helpers::JourneyHelper
  include Helpers::JourneyAssertionHelper
  include Helpers::JourneyStepHelper

  include_context "retrieve latest application data"
  include_context "Stub previously funding check for all courses" do
    let(:api_call_get_an_identity_id) { nil }
    let(:api_call_trn) { "1234567" }
  end
  include_context "Enable Get An Identity integration"

  context "when JavaScript is enabled", :js do
    scenario("registration journey when entering an email for a user record without a TRN after being removed from the pilot (with JS)") { run_scenario(js: true) }
  end

  context "when JavaScript is disabled", :no_js do
    include_context "use rack_test driver"
    scenario("registration journey when entering an email for a user record without a TRN after being removed from the pilot (without JS)") { run_scenario(js: false) }
  end

  # This controls what is returned from the Get An Identity API
  let(:user_trn) { "" }

  let(:non_pilot_user_email) { "mail@example.com" }

  before do
    # create the user that the user will log in as in the non-pilot journey
    create(:user, email: non_pilot_user_email, trn: nil)
  end

  # This spec was created to replicate a bug that’s triggered 80 times over about 3 months and leads to a full error page
  # for users who encounter it. This flow seems like such an extreme edge-case that it can’t be the only trigger for this bug.
  #
  # 1. Go through the GAI flow without a verified TRN, return and be removed from the pilot as no TRN is returned.
  # 2. Go through the non-GAI flow until you reach the email input, enter a different email to the one you used on GAI
  #    for a user that already exists that doesn’t have a TRN on the record. You will be logged in as this user.
  # 3. Enter your TRN on the TRN step, it is required and you cannot proceed without one.
  # 4. Proceed and complete the Choose your NPQ page.
  # 5. Encounter a 500 error.
  #
  # You encounter a 500 error here because after the Choose your NPQ page a funding eligibility check is performed.
  # This check requires your TRN.
  #
  # Since your email was already on a user record when you entered it on the email input page you were logged in as
  # that user but importantly that user did not have your feature flag ID copied across
  # (since it’s only copied for new users) and so your feature flags reset to the flags for that user.
  # This user’s flags more than likely would leave you as a part of the pilot.
  #
  # Because you were still considered a part of the pilot during the eligibility check the TRN for the user would be
  # looked up on the user record in the wrong place looking where it would be for GAI users instead of for non-GAI users.
  # Then it tries to use nil when constructing the URL and fails.
  # The solution I found was to just copy feature flags during log in for new and existing uses.
  # This overall is a better approach IMO because it’s not a great idea to have any user suddenly jump from one set of flags to another.
  #
  # The solution was to copy the feature flags from the session ID to the user even if it isn't a new user being created.
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
      page.choose("A school", visible: :all)
    end

    expect_page_to_have(path: "/registration/teacher-reference-number", submit_form: true) do
      page.choose("Yes", visible: :all)
    end

    expect_page_to_have(path: "/registration/contact-details", submit_form: true) do
      expect(page).to have_text("What’s your email address?")

      page.fill_in "What’s your email address?", with: non_pilot_user_email
    end

    expect_page_to_have(path: "/registration/confirm-email", submit_form: true) do
      expect(page).to have_text("Confirm your email address")
      expect(page).to have_text(non_pilot_user_email)
      page.fill_in "Enter your code", with: "000000"
      page.click_button("Continue")

      expect(page).to have_text("Confirm your email address")
      expect(page).to have_text("Code is not correct")

      code = ActionMailer::Base.deliveries.last[:personalisation].unparsed_value[:code]

      page.fill_in "Enter your code", with: code
      page.click_button("Continue")
    end

    expect_page_to_have(path: "/registration/qualified-teacher-check", submit_form: true) do
      expect(page).to have_text("Check your details")

      page.fill_in "Teacher reference number (TRN)", with: "1234567"
      page.fill_in "Full name", with: "John Doe"
      page.fill_in "Day", with: "13"
      page.fill_in "Month", with: "12"
      page.fill_in "Year", with: "1980"
      page.fill_in "National Insurance number", with: "AB123456C"
    end

    choose_a_school(js:, location: "manchester", name: "open")

    expect_page_to_have(path: "/registration/choose-your-npq", submit_form: true) do
      expect(page).to have_text("Which NPQ do you want to do?")
      page.choose("Headship", visible: :all)
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
      page.choose "My trust is paying", visible: :all
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
          "Full name" => "John Doe",
          "TRN" => "1234567",
          "Date of birth" => "13 December 1980",
          "National Insurance number" => "AB123456C",
          "Email" => non_pilot_user_email,
          "Course" => "Headship",
          "Lead provider" => "Teach First",
          "Workplace" => "open manchester school",
          "How is your NPQ being paid for?" => "My trust is paying",
          "What setting do you work in?" => "A school",
          "Where do you work?" => "England",
        },
      )
    end

    expect_page_to_have(path: "/registration/confirmation", submit_form: false) do
      expect(page).to have_text("Your initial registration is complete")
      expect(page).to have_text("The Early Headship Coaching Offer is a package of structured face-to-face support for new headteachers.")
    end

    expect(User.count).to eql(1)

    User.last.tap do |user|
      expect(user.email).to eql(non_pilot_user_email)
      expect(user.full_name).to eql("John Doe")
      expect(user.trn).to eql("1234567")
      expect(user.trn_verified).to be_truthy
      expect(user.trn_auto_verified).to be_truthy
      expect(user.date_of_birth).to eql(Date.new(1980, 12, 13))
      expect(user.national_insurance_number).to be_blank
      expect(user.applications.count).to eql(1)

      user.applications.first.tap do |application|
        expect(application.eligible_for_funding).to be_falsey
        expect(application.funding_choice).to eql("trust")
      end
    end

    navigate_to_page(path: "/account", axe_check: false, submit_form: false) do
      expect(page).to have_text("Teach First")
      expect(page).to have_text("Headship")
    end

    visit "/registration/share-provider"

    expect_page_to_have(path: "/", axe_check: false, submit_form: false) do
      expect(page).to have_content("Before you start")
    end

    expect(retrieve_latest_application_user_data).to eq(
      "active_alert" => false,
      "admin" => false,
      "date_of_birth" => "1980-12-13",
      "ecf_id" => nil,
      "email" => non_pilot_user_email,
      "flipper_admin_access" => false,
      "full_name" => "John Doe",
      "get_an_identity_id_synced_to_ecf" => false,
      "national_insurance_number" => nil,
      "otp_expires_at" => nil,
      "otp_hash" => nil,
      "provider" => nil,
      "raw_tra_provider_data" => nil,
      "trn" => "1234567",
      "trn_auto_verified" => true,
      "trn_verified" => true,
      "uid" => nil,
    )

    expect(retrieve_latest_application_data).to eq(
      "cohort" => 2022,
      "course_id" => Course.find_by(identifier: "npq-headship").id,
      "ecf_id" => nil,
      "eligible_for_funding" => false,
      "employer_name" => nil,
      "employment_type" => nil,
      "employment_role" => nil,
      "funding_choice" => "trust",
      "funding_eligiblity_status_code" => "ineligible_establishment_type",
      "kind_of_nursery" => nil,
      "itt_provider" => nil,
      "lead_mentor" => false,
      "headteacher_status" => nil,
      "lead_provider_id" => LeadProvider.find_by(name: "Teach First").id,
      "private_childcare_provider_urn" => nil,
      "school_urn" => "100000",
      "targeted_delivery_funding_eligibility" => false,
      "teacher_catchment" => "england",
      "teacher_catchment_country" => nil,
      "teacher_catchment_synced_to_ecf" => false,
      "ukprn" => nil,
      "works_in_childcare" => false,
      "works_in_school" => true,
      "works_in_nursery" => nil,
      "work_setting" => "a_school",
      "raw_application_data" => {
        "active_alert" => false,
        "can_share_choices" => "1",
        "chosen_provider" => "yes",
        "confirmed_email" => non_pilot_user_email,
        "course_identifier" => "npq-headship",
        "date_of_birth" => "1980-12-13",
        "email" => non_pilot_user_email,
        "full_name" => "John Doe",
        "funding" => "trust",
        "institution_identifier" => "School-100000",
        "institution_location" => "manchester",
        "institution_name" => js ? "" : "open",
        "lead_provider_id" => "9",
        "national_insurance_number" => "AB123456C",
        "teacher_catchment" => "england",
        "teacher_catchment_country" => nil,
        "trn" => "1234567",
        "trn_auto_verified" => true,
        "trn_knowledge" => "yes",
        "trn_verified" => true,
        "verified_trn" => "1234567",
        "works_in_school" => "yes",
        "works_in_childcare" => "no",
        "work_setting" => "a_school",
      },
    )
  end
end
