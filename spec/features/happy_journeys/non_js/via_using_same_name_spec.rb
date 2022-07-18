require "rails_helper"

RSpec.feature "Happy journeys", type: :feature do
  include Helpers::JourneyHelper
  include Helpers::JourneyAssertionHelper

  around do |example|
    Capybara.current_driver = :rack_test

    example.run

    Capybara.current_driver = Capybara.default_driver
  end

  scenario "registration journey via using same name" do
    stub_participant_validation_request

    navigate_to_page("/", submit_form: false, axe_check: false) do
      expect(page).to have_text("Before you start")
      page.click_link("Start now")
    end

    now_i_should_be_on_page("/registration/provider-check") do
      expect(page).to have_text("Have you already chosen an NPQ and provider?")
      page.choose("Yes", visible: :all)
    end

    now_i_should_be_on_page("/registration/teacher-catchment", axe_check: false) do
      page.choose("England", visible: :all)
    end

    now_i_should_be_on_page("/registration/work-in-school") do
      page.choose("Yes", visible: :all)
    end

    now_i_should_be_on_page("/registration/teacher-reference-number") do
      page.choose("Yes", visible: :all)
    end

    now_i_should_be_on_page("/registration/contact-details") do
      expect(page).to have_text("What's your email address?")
      page.fill_in "What's your email address?", with: "user@example.com"
    end

    now_i_should_be_on_page("/registration/confirm-email") do
      expect(page).to have_text("Confirm your code")
      expect(page).to have_text("user@example.com")

      code = ActionMailer::Base.deliveries.last[:personalisation].unparsed_value[:code]

      page.fill_in("Enter your code", with: code)
    end

    now_i_should_be_on_page("/registration/qualified-teacher-check") do
      expect(page).to have_text("Check your details")

      page.fill_in "Teacher reference number (TRN)", with: "1234567"
      page.fill_in "Full name", with: "John Doe"
      page.fill_in "Day", with: "13"
      page.fill_in "Month", with: "12"
      page.fill_in "Year", with: "1980"
      page.fill_in "National Insurance number", with: "AB123456C"
    end

    School.create!(urn: 100_000, name: "open manchester school", address_1: "street 1", town: "manchester", establishment_status_code: "1")
    School.create!(urn: 100_001, name: "closed manchester school", address_1: "street 2", town: "manchester", establishment_status_code: "2")
    School.create!(urn: 100_002, name: "open newcastle school", address_1: "street 3", town: "newcastle", establishment_status_code: "1")

    now_i_should_be_on_page("/registration/find-school") do
      expect(page).to have_text("Where is your school, college or academy trust?")
      page.fill_in "Workplace location", with: "manchester"
    end

    now_i_should_be_on_page("/registration/choose-school") do
      expect(page).to have_text("Choose your workplace")
      expect(page).to have_text("Choose from schools, trusts and 16 to 19 educational settings located in manchester")

      within ".npq-js-hidden" do
        page.fill_in "Enter the name of your workplace", with: "open"
      end

      page.click_button("Continue")

      expect(page).to have_text("Choose your workplace")
      page.choose "open manchester school"
    end

    stub_request(:get, "https://ecf-app.gov.uk/api/v1/npq-funding/1234567?npq_course_identifier=npq-headship")
      .with(
        headers: {
          "Authorization" => "Bearer ECFAPPBEARERTOKEN",
        },
      )
      .to_return(
        status: 200,
        body: previously_funded_response(false),
        headers: {
          "Content-Type" => "application/vnd.api+json",
        },
      )

    now_i_should_be_on_page("/registration/choose-your-npq") do
      expect(page).to have_text("What are you applying for?")
      page.choose("NPQ for Headship (NPQH)")
    end

    now_i_should_be_on_page("/registration/ineligible-for-funding", submit_form: false) do
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

    now_i_should_be_on_page("/registration/funding-your-npq") do
      expect(page).to have_text("How is your course being paid for?")
      page.choose "My trust is paying"
    end

    now_i_should_be_on_page("/registration/choose-your-provider") do
      expect(page).to have_text("Select your provider")
      page.choose("Teach First", visible: :all)
    end

    now_i_should_be_on_page("/registration/share-provider") do
      expect(page).to have_text("Sharing your NPQ information")
      page.check("Yes, I agree my information can be shared", visible: :all)
    end

    allow(ApplicationSubmissionJob).to receive(:perform_later).with(anything)

    now_i_should_be_on_page("/registration/check-answers", submit_button_text: "Submit") do
      and_the_check_your_answers_page_should_contain(
        {
          "Where do you work?" => "England",
          "Do you work in a school, academy trust, or 16 to 19 educational setting?" => "Yes",
          "Full name" => "John Doe",
          "TRN" => "1234567",
          "Date of birth" => "13 December 1980",
          "National Insurance number" => "AB123456C",
          "Email" => "user@example.com",
          "Course" => "NPQ for Headship (NPQH)",
          "Lead provider" => "Teach First",
          "Workplace" => "open manchester school",
          "How is your NPQ being paid for?" => "My trust is paying",
        },
      )
    end

    now_i_should_be_on_page("/registration/confirmation", submit_form: false) do
      expect(page).to have_text("Your initial registration is complete")
      expect(page).to have_text("The Early Headship Coaching Offer is a package of structured face-to-face support for new headteachers.")
    end

    expect(User.count).to eql(1)
    expect(User.last.applications.count).to eql(1)

    navigate_to_page("/account", submit_form: false, axe_check: false) do
      expect(page).to have_text("Teach First")
      expect(page).to have_text("NPQ for Headship (NPQH)")
    end

    visit("/registration/check-answers")
    expect(page.current_path).to eql("/")

    expect(retrieve_latest_application_user_data).to eq(
      "active_alert" => false,
      "admin" => false,
      "date_of_birth" => "1980-12-13",
      "ecf_id" => nil,
      "email" => "user@example.com",
      "full_name" => "John Doe",
      "national_insurance_number" => nil,
      "otp_expires_at" => nil,
      "otp_hash" => nil,
      "trn" => "1234567",
      "trn_auto_verified" => true,
      "trn_verified" => true,
    )
    expect(retrieve_latest_application_data).to eq(
      "cohort" => 2022,
      "course_id" => Course.find_by_code(code: :NPQH).id,
      "ecf_id" => nil,
      "eligible_for_funding" => false,
      "employer_name" => nil,
      "employment_role" => nil,
      "funding_choice" => "trust",
      "funding_eligiblity_status_code" => "ineligible_establishment_type",
      "headteacher_status" => nil,
      "kind_of_nursery" => nil,
      "lead_provider_id" => LeadProvider.find_by(name: "Teach First").id,
      "private_childcare_provider_urn" => nil,
      "school_urn" => "100000",
      "targeted_delivery_funding_eligibility" => false,
      "targeted_support_funding_eligibility" => false,
      "teacher_catchment" => "england",
      "teacher_catchment_country" => nil,
      "ukprn" => nil,
      "works_in_childcare" => false,
      "works_in_nursery" => false,
      "works_in_school" => true,
      "raw_application_data" => {
        "active_alert" => false,
        "can_share_choices" => "1",
        "chosen_provider" => "yes",
        "confirmed_email" => "user@example.com",
        "course_id" => Course.find_by_code(code: :NPQH).id.to_s,
        "date_of_birth" => "1980-12-13",
        "email" => "user@example.com",
        "full_name" => "John Doe",
        "funding" => "trust",
        "institution_identifier" => "School-100000",
        "institution_location" => "manchester",
        "institution_name" => "open",
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
      },
    )
  end
end
