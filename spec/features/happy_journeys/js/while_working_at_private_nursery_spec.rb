require "rails_helper"

RSpec.feature "Happy journeys", type: :feature do
  include Helpers::JourneyHelper
  include_context "retrieve latest application data"

  scenario "registration journey while working at private nursery" do
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
    page.choose("England", visible: :all)
    page.click_button("Continue")

    expect(page.current_path).to eql("/registration/work-in-school")
    page.choose("No", visible: :all)
    page.click_button("Continue")

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
          nino: "AB123456C",
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
    page.fill_in "National Insurance number", with: "AB123456C"
    page.click_button("Continue")

    School.create!(urn: 100_000, name: "open manchester school", address_1: "street 1", town: "manchester", establishment_status_code: "1")

    expect(page).to be_axe_clean
    expect(page).to have_text("Do you work in early years or childcare?")
    page.choose("Yes", visible: :all)
    page.click_button("Continue")

    expect(page).to be_axe_clean
    expect(page).to have_text("Do you work in a nursery?")
    page.choose("Yes", visible: :all)
    page.click_button("Continue")

    expect(page).to be_axe_clean
    expect(page).to have_text("What kind of nursery do you work in?")
    page.choose("Private nursery", visible: :all)
    page.click_button("Continue")

    expect(page).to be_axe_clean
    expect(page).to have_text("Do you or your employer have an Ofsted unique reference number (URN)?")
    page.choose("Yes", visible: :all)
    page.click_button("Continue")

    private_childcare_provider = PrivateChildcareProvider.create!(
      provider_urn: "EY123456", provider_name: "searchable childcare provider",
      address_1: "street 1", town: "manchester",
      early_years_individual_registers: %w[CCR VCR EYR]
    )

    expect(page).to be_axe_clean
    expect(page).to have_text("Enter your or your employer's URN")
    within ".npq-js-reveal" do
      page.fill_in "private-childcare-provider-picker", with: "EY123"
    end

    expect(page).to have_content("EY123456 - searchable childcare provider - street 1, manchester")
    page.find("#private-childcare-provider-picker__option--0").click
    page.click_button("Continue")

    Course::COURSE_ECF_ID_TO_IDENTIFIER_MAPPING.each_value do |course_identifier|
      stub_request(:get, "https://ecf-app.gov.uk/api/v1/npq-funding/1234567?npq_course_identifier=#{course_identifier}")
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
    end

    eyl_course = ["NPQ for Early Years Leadership (NPQEYL)"]

    ineligible_courses = Forms::ChooseYourNpq.new.options.map(&:text) - eyl_course

    ineligible_courses.each do |course|
      expect(page).to have_text("What are you applying for?")
      page.choose(course, visible: :all)
      page.click_button("Continue")

      expect(page).not_to have_text("If your provider accepts your application, you’ll qualify for DfE funding")
      page.click_link("Back")
    end

    expect(page).to be_axe_clean
    expect(page).to have_text("What are you applying for?")
    page.choose("NPQ for Early Years Leadership (NPQEYL)", visible: :all)
    page.click_button("Continue")

    expect(page).to be_axe_clean
    expect(page).to have_text("If your provider accepts your application, you’ll qualify for DfE funding")
    expect(page).to have_text("You’ll only be eligible for DfE funding for this NPQ once. If you start this NPQ, and then withdraw or fail, you will not be funded again for the same course.")
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
      "Course" => "NPQ for Early Years Leadership (NPQEYL)",
      "Date of birth" => "13 December 1980",
      "Do you work in a nursery?" => "Yes",
      "Do you work in a school, academy trust, or 16 to 19 educational setting?" => "No",
      "Do you work in early years or childcare?" => "Yes",
      "Email" => "user@example.com",
      "Full name" => "John Doe",
      "Lead provider" => "Teach First",
      "National Insurance number" => "AB123456C",
      "Ofsted registration details" => private_childcare_provider.registration_details,
      "TRN" => "1234567",
      "Type of nursery" => "Private nursery",
      "Where do you work?" => "England",
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
      "course_id" => Course.find_by_code(code: :NPQEYL).id,
      "ecf_id" => nil,
      "eligible_for_funding" => true,
      "employer_name" => nil,
      "employment_role" => nil,
      "funding_choice" => nil,
      "funding_eligiblity_status_code" => "funded",
      "headteacher_status" => nil,
      "kind_of_nursery" => "private_nursery",
      "lead_provider_id" => LeadProvider.find_by(name: "Teach First").id,
      "private_childcare_provider_urn" => "EY123456",
      "school_urn" => nil,
      "targeted_delivery_funding_eligibility" => false,
      "targeted_support_funding_eligibility" => false,
      "teacher_catchment" => "england",
      "teacher_catchment_country" => nil,
      "ukprn" => nil,
      "works_in_childcare" => true,
      "works_in_nursery" => true,
      "works_in_school" => false,
      "raw_application_data" => {
        "active_alert" => false,
        "can_share_choices" => "1",
        "chosen_provider" => "yes",
        "confirmed_email" => "user@example.com",
        "course_id" => Course.find_by_code(code: :NPQEYL).id.to_s,
        "date_of_birth" => "1980-12-13",
        "email" => "user@example.com",
        "full_name" => "John Doe",
        "has_ofsted_urn" => "yes",
        "institution_identifier" => "PrivateChildcareProvider-EY123456",
        "institution_name" => "",
        "kind_of_nursery" => "private_nursery",
        "lead_provider_id" => "9",
        "national_insurance_number" => "AB123456C",
        "teacher_catchment" => "england",
        "teacher_catchment_country" => nil,
        "trn" => "1234567",
        "trn_auto_verified" => true,
        "trn_knowledge" => "yes",
        "trn_verified" => true,
        "verified_trn" => "1234567",
        "works_in_childcare" => "yes",
        "works_in_nursery" => "yes",
        "works_in_school" => "no",
      },
    )
  end
end
