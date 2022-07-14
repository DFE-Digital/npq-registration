require "rails_helper"

RSpec.feature "Happy journeys", type: :feature do
  include Helpers::JourneyHelper
  include_context "retrieve latest application data"

  scenario "registration journey when outside of catchment area" do
    visit "/"
    expect(page).to have_text("Before you start")
    page.click_link("Start now")

    expect(page).to be_axe_clean
    expect(page).to have_text("Have you already chosen an NPQ and provider?")
    page.choose("Yes", visible: :all)
    page.click_button("Continue")

    # expect(page).to be_axe_clean
    # TODO: aria-expanded
    expect(page.current_path).to eql("/registration/teacher-catchment")
    page.choose("Another country", visible: :all)
    within "[data-module='app-country-autocomplete'" do
      page.fill_in "Which country do you teach in?", with: "Falk"
    end

    expect(page).to have_content("Falkland Islands")
    page.find("#registration-wizard-teacher-catchment-country-field__option--0").click

    page.click_button("Continue")

    expect(page.current_path).to eql("/registration/work-in-school")
    page.choose("Yes", visible: :all)
    page.click_button("Continue")

    expect(page).to be_axe_clean
    expect(page.current_path).to eql("/registration/teacher-reference-number")
    page.choose("No, I need help getting one", visible: :all)
    page.click_button("Continue")

    expect(page).to be_axe_clean
    expect(page).to have_text("Get a Teacher Reference Number (TRN)")
    page.click_link("Back")

    expect(page).to be_axe_clean
    expect(page.current_path).to eql("/registration/teacher-reference-number")
    page.choose("Yes", visible: :all)
    page.click_button("Continue")

    expect(page).to be_axe_clean
    expect(page.current_path).to include("contact-details")
    expect(page).to have_text("What's your email address?")
    page.fill_in "What's your email address?", with: "user@example.com"
    page.click_button("Continue")

    expect(page).to be_axe_clean
    expect(page).to have_text("Confirm your code")
    expect(page).to have_text("user@example.com")
    page.click_button("Continue")

    code = ActionMailer::Base.deliveries.last[:personalisation].unparsed_value[:code]

    expect(page).to be_axe_clean
    page.fill_in "Enter your code", with: code
    page.click_button("Continue")

    stub_request(:post, "https://ecf-app.gov.uk/api/v1/participant-validation")
      .with(
        headers: {
          "Authorization" => "Bearer ECFAPPBEARERTOKEN",
        },
        body: {
          trn: "1234567",
          date_of_birth: "1980-12-13",
          full_name: "John Doe",
          nino: "",
        },
      )
      .to_return(status: 200, body: participant_validator_response, headers: {})

    expect(page).to be_axe_clean
    expect(page).to have_text("Check your details")
    page.fill_in "Teacher reference number (TRN)", with: "1234567"
    page.fill_in "Full name", with: "John Doe"
    page.fill_in "Day", with: "13"
    page.fill_in "Month", with: "12"
    page.fill_in "Year", with: "1980"
    page.click_button("Continue")

    School.create!(urn: 100_000, name: "open manchester school", address_1: "street 1", town: "manchester", establishment_status_code: "1")

    expect(page).to be_axe_clean
    expect(page).to have_text("What are you applying for?")
    page.choose("NPQ for Senior Leadership (NPQSL)", visible: :all)
    page.click_button("Continue")

    expect(page).to be_axe_clean
    expect(page).to have_text("DfE scholarship funding is not available")
    expect(page).to have_text("To be eligible for scholarship funding for")
    expect(page).to have_text("To be eligible for scholarship funding for")
    expect(page).to have_text("state-funded schools")
    expect(page).to have_text("state-funded 16 to 19 organisations")
    expect(page).to have_text("independent special schools")
    expect(page).to have_text("virtual schools")
    expect(page).to have_text("hospital schools")
    expect(page).to have_text("young offenders institutions")
    page.click_link("Continue")

    expect(page).to be_axe_clean
    expect(page).to have_text("How is your course being paid for?")
    page.choose "I am paying", visible: :all
    page.click_button("Continue")

    expect(page).to be_axe_clean
    expect(page).to have_text("Select your provider")
    page.choose("Teach First", visible: :all)
    page.click_button("Continue")

    expect(page).to be_axe_clean
    expect(page).to have_text("Sharing your NPQ information")
    page.check("Yes, I agree my information can be shared", visible: :all)
    page.click_button("Continue")

    check_answers_page = CheckAnswersPage.new

    expect(page).to be_axe_clean
    expect(check_answers_page).to be_displayed

    summary_data = check_answers_page.summary_list.rows.map { |summary_item|
      [summary_item.key, summary_item.value]
    }.to_h

    expect(summary_data).to eql(
      "Full name" => "John Doe",
      "TRN" => "1234567",
      "Date of birth" => "13 December 1980",
      "Email" => "user@example.com",
      "Course" => "NPQ for Senior Leadership (NPQSL)",
      "How is your NPQ being paid for?" => "I am paying",
      "Do you work in a school, academy trust, or 16 to 19 educational setting?" => "Yes",
      "Lead provider" => "Teach First",
      "Where do you work?" => "Falkland Islands",
    )

    allow(ApplicationSubmissionJob).to receive(:perform_later).with(anything)

    page.click_button("Submit")

    expect(page).to be_axe_clean

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
      "course_id" => Course.find_by_code(code: :NPQSL).id,
      "ecf_id" => nil,
      "eligible_for_funding" => false,
      "employer_name" => nil,
      "employment_role" => nil,
      "funding_choice" => "self",
      "funding_eligiblity_status_code" => "no_institution",
      "headteacher_status" => nil,
      "kind_of_nursery" => nil,
      "lead_provider_id" => LeadProvider.find_by(name: "Teach First").id,
      "private_childcare_provider_urn" => nil,
      "school_urn" => nil,
      "targeted_delivery_funding_eligibility" => false,
      "targeted_support_funding_eligibility" => false,
      "teacher_catchment" => "another",
      "teacher_catchment_country" => "Falkland Islands",
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
        "funding" => "self",
        "lead_provider_id" => "9",
        "national_insurance_number" => "",
        "teacher_catchment" => "another",
        "teacher_catchment_country" => "Falkland Islands",
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
