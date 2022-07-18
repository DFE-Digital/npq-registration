require "rails_helper"

RSpec.feature "Happy journeys", type: :feature do
  include Helpers::JourneyHelper

  around do |example|
    Capybara.current_driver = :rack_test

    example.run

    Capybara.current_driver = Capybara.default_driver
  end

  scenario "registration journey via using old name and not headship" do
    visit "/"
    expect(page).to have_text("Before you start")
    page.click_link("Start now")

    expect(page).to have_text("Have you already chosen an NPQ and provider?")
    page.choose("Yes")
    page.click_button("Continue")

    expect(page.current_path).to eql("/registration/teacher-catchment")
    page.choose("England")
    page.click_button("Continue")

    expect(page.current_path).to eql("/registration/work-in-school")
    page.choose("Yes")
    page.click_button("Continue")

    expect(page.current_path).to eql("/registration/teacher-reference-number")
    page.choose("No, I need help getting one")
    page.click_button("Continue")

    expect(page).to have_text("Get a Teacher Reference Number (TRN)")
    page.click_link("Back")

    expect(page.current_path).to eql("/registration/teacher-reference-number")
    page.choose("Yes")
    page.click_button("Continue")

    expect(page.current_path).to include("contact-details")
    expect(page).to have_text("What's your email address?")
    page.fill_in "What's your email address?", with: "user@example.com"
    page.click_button("Continue")

    expect(page).to have_text("Confirm your code")
    expect(page).to have_text("user@example.com")
    page.click_button("Continue")

    code = ActionMailer::Base.deliveries.last[:personalisation].unparsed_value[:code]

    page.fill_in "Enter your code", with: code
    page.click_button("Continue")

    stub_request(:post, "https://ecf-app.gov.uk/api/v1/participant-validation")
      .with(
        headers: {
          "Authorization" => "Bearer ECFAPPBEARERTOKEN",
        },
        body: {
          trn: "12345",
          date_of_birth: "1980-12-13",
          full_name: "John Doe",
          nino: "AB123456C",
        },
      )
      .to_return(status: 200, body: participant_validator_response(trn: "12345"), headers: {})

    expect(page).to have_text("Check your details")
    page.fill_in "Teacher reference number (TRN)", with: "RP12/345"
    page.fill_in "Full name", with: "John Doe"
    page.fill_in "Day", with: "13"
    page.fill_in "Month", with: "12"
    page.fill_in "Year", with: "1980"
    page.fill_in "National Insurance number", with: "AB123456C"
    page.click_button("Continue")

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

    expect(page).to have_text("Where is your school, college or academy trust?")
    page.fill_in "Workplace location", with: "manchester"
    page.click_button("Continue")

    expect(page).to have_text("Choose your workplace")
    expect(page).to have_text("Choose from schools, trusts and 16 to 19 educational settings located in manchester")

    within ".npq-js-hidden" do
      page.fill_in "Enter the name of your workplace", with: "open"
    end
    page.click_button("Continue")

    expect(page).to have_text("Choose your workplace")
    page.choose "open manchester school"
    page.click_button("Continue")

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

    expect(page).to have_text("What are you applying for?")
    page.choose("NPQ for Senior Leadership (NPQSL)")
    page.click_button("Continue")

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

    expect(page).to have_text("If your provider accepts your application, you’ll qualify for DfE funding")
    page.click_button("Continue")

    expect(page).to have_text("Select your provider")
    page.choose("Teach First")
    page.click_button("Continue")

    expect(page).to have_text("Sharing your NPQ information")
    page.check("Yes, I agree my information can be shared")
    page.click_button("Continue")

    check_answers_page = CheckAnswersPage.new

    expect(check_answers_page).to be_displayed

    summary_data = check_answers_page.summary_list.rows.map { |summary_item|
      [summary_item.key, summary_item.value]
    }.to_h

    expect(summary_data).to eql(
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
    )

    allow(ApplicationSubmissionJob).to receive(:perform_later).with(anything)

    page.click_button("Submit")

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
