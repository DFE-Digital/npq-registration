require "rails_helper"

RSpec.feature "Happy journeys", type: :feature do
  include Helpers::JourneyHelper
  include Helpers::JourneyAssertionHelper

  include_context "stub course ecf to identifier mappings"

  around do |example|
    Capybara.current_driver = :rack_test

    example.run

    Capybara.current_driver = Capybara.default_driver
  end

  scenario "registration journey via using old name and not headship" do
    stub_participant_validation_request(trn: "12345", response: { trn: "12345" })

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
      page.choose("No, I need help getting one", visible: :all)
    end

    now_i_should_be_on_page("/registration/dont-have-teacher-reference-number", submit_form: false) do
      expect(page).to have_text("Get a Teacher Reference Number (TRN)")

      page.click_link("Back")
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

      page.fill_in "Teacher reference number (TRN)", with: "RP12/345"
      page.fill_in "Full name", with: "John Doe"
      page.fill_in "Day", with: "13"
      page.fill_in "Month", with: "12"
      page.fill_in "Year", with: "1980"
      page.fill_in "National Insurance number", with: "AB123456C"
    end

    School.create!(
      urn: 100_000,
      name: "open manchester school",
      address_1: "street 1",
      town: "manchester",
      establishment_status_code: "1",
      establishment_type_code: "1",
      high_pupil_premium: true,
      number_of_pupils: 100,
    )

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

    stub_request(:get, "https://ecf-app.gov.uk/api/v1/npq-funding/RP12%2F345?npq_course_identifier=npq-senior-leadership")
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
      page.choose("NPQ for Senior Leadership (NPQSL)")
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

    now_i_should_be_on_page("/registration/possible-funding") do
      expect(page).to have_text("If your provider accepts your application, you’ll qualify for DfE funding")
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

    now_i_should_be_on_page("/registration/check-answers", submit_form: true, submit_button_text: "Submit") do
      expect_check_answers_page_to_have_answers(
        {
          "Where do you work?" => "England",
          "Do you work in a school, academy trust, or 16 to 19 educational setting?" => "Yes",
          "Full name" => "John Doe",
          "TRN" => "RP12/345",
          "Date of birth" => "13 December 1980",
          "National Insurance number" => "AB123456C",
          "Email" => "user@example.com",
          "Course" => "NPQ for Senior Leadership (NPQSL)",
          "Workplace" => "open manchester school",
          "Lead provider" => "Teach First",
        },
      )
    end

    now_i_should_be_on_page("/registration/confirmation", submit_form: false) do
      expect(page).to have_text("Your initial registration is complete")
    end

    expect(User.count).to eql(1)
    expect(Application.count).to eql(1)

    visit "/"
    visit "/registration/confirmation"
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
      "trn" => "0012345",
      "trn_auto_verified" => true,
      "trn_verified" => true,
    )

    expect(retrieve_latest_application_data).to eq(
      "cohort" => 2022,
      "course_id" => Course.find_by_code(code: :NPQSL).id,
      "ecf_id" => nil,
      "eligible_for_funding" => true,
      "employer_name" => nil,
      "employment_role" => nil,
      "funding_choice" => nil,
      "funding_eligiblity_status_code" => "funded",
      "headteacher_status" => nil,
      "kind_of_nursery" => nil,
      "lead_provider_id" => LeadProvider.find_by(name: "Teach First").id,
      "private_childcare_provider_urn" => nil,
      "school_urn" => "100000",
      "targeted_delivery_funding_eligibility" => true,
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
        "course_id" => Course.find_by_code(code: :NPQSL).id.to_s,
        "date_of_birth" => "1980-12-13",
        "email" => "user@example.com",
        "full_name" => "John Doe",
        "institution_identifier" => "School-100000",
        "institution_location" => "manchester",
        "institution_name" => "open",
        "lead_provider_id" => "9",
        "national_insurance_number" => "AB123456C",
        "teacher_catchment" => "england",
        "teacher_catchment_country" => nil,
        "trn" => "RP12/345",
        "trn_auto_verified" => true,
        "trn_knowledge" => "yes",
        "trn_verified" => true,
        "verified_trn" => "12345",
        "works_in_school" => "yes",
      },
    )
  end
end
