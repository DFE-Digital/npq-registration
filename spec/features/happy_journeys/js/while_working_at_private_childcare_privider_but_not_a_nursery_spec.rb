require "rails_helper"

RSpec.feature "Happy journeys", type: :feature do
  include Helpers::JourneyHelper
  include Helpers::JourneyAssertionHelper

  include_context "retrieve latest application data"
  include_context "stub course ecf to identifier mappings"

  scenario "registration journey while working at private childcare provider but not a nursery" do
    stub_participant_validation_request

    navigate_to_page(path: "/", submit_form: false, axe_check: false) do
      expect(page).to have_text("Before you start")
      page.click_link("Start now")
    end

    expect_page_to_have(path: "/registration/provider-check", submit_form: true) do
      expect(page).to have_text("Have you already chosen an NPQ and provider?")
      page.choose("Yes", visible: :all)
    end

    # TODO: aria-expanded
    expect_page_to_have(path: "/registration/teacher-catchment", axe_check: false, submit_form: true) do
      page.choose("England", visible: :all)
    end

    expect_page_to_have(path: "/registration/work-in-school", submit_form: true) do
      page.choose("No", visible: :all)
    end

    expect_page_to_have(path: "/registration/teacher-reference-number", submit_form: true) do
      page.choose("Yes", visible: :all)
    end

    expect_page_to_have(path: "/registration/contact-details", submit_form: true) do
      expect(page).to have_text("What's your email address?")
      page.fill_in "What's your email address?", with: "user@example.com"
    end

    expect_page_to_have(path: "/registration/confirm-email", submit_form: true) do
      expect(page).to have_text("Confirm your code")
      expect(page).to have_text("user@example.com")

      code = ActionMailer::Base.deliveries.last[:personalisation].unparsed_value[:code]

      page.fill_in("Enter your code", with: code)
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

    School.create!(urn: 100_000, name: "open manchester school", address_1: "street 1", town: "manchester", establishment_status_code: "1")

    expect_page_to_have(path: "/registration/work-in-childcare", submit_form: true) do
      expect(page).to have_text("Do you work in early years or childcare?")
      page.choose("Yes", visible: :all)
    end

    expect_page_to_have(path: "/registration/work-in-nursery", submit_form: true) do
      expect(page).to have_text("Do you work in a nursery?")
      page.choose("No", visible: :all)
    end

    expect_page_to_have(path: "/registration/have-ofsted-urn", submit_form: true) do
      expect(page).to have_text("Do you or your employer have an Ofsted unique reference number (URN)?")
      page.choose("Yes", visible: :all)
    end

    private_childcare_provider = PrivateChildcareProvider.create!(
      provider_urn: "EY123456",
      provider_name: "searchable childcare provider",
      address_1: "street 1",
      town: "manchester",
      early_years_individual_registers: %w[CCR VCR EYR],
    )

    expect_page_to_have(path: "/registration/choose-private-childcare-provider", submit_form: true) do
      expect(page).to have_text("Enter your or your employer's URN")
      within ".npq-js-reveal" do
        page.fill_in "private-childcare-provider-picker", with: "EY123"
      end

      expect(page).to have_content("EY123456 - searchable childcare provider - street 1, manchester")
      page.find("#private-childcare-provider-picker__option--0").click
    end

    eyl_course = ["NPQ for Early Years Leadership (NPQEYL)"]

    ineligible_courses = Forms::ChooseYourNpq.new.options.map(&:text) - eyl_course

    ineligible_courses.each do |course|
      expect_page_to_have(path: "/registration/choose-your-npq", submit_form: true) do
        expect(page).to have_text("What are you applying for?")
        page.choose(course, visible: :all)
      end

      expect(page).not_to have_text("If your provider accepts your application, you???ll qualify for DfE funding")
      page.click_link("Back")
    end

    expect_page_to_have(path: "/registration/choose-your-npq", submit_form: true) do
      expect(page).to have_text("What are you applying for?")
      page.choose("NPQ for Early Years Leadership (NPQEYL)", visible: :all)
    end

    expect_page_to_have(path: "/registration/possible-funding", submit_form: true) do
      expect(page).to have_text("If your provider accepts your application, you???ll qualify for DfE funding")
      expect(page).to have_text("You???ll only be eligible for DfE funding for this NPQ once. If you start this NPQ, and then withdraw or fail, you will not be funded again for the same course.")
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

    expect_page_to_have(path: "/registration/check-answers", submit_form: true, submit_button_text: "Submit") do
      expect_check_answers_page_to_have_answers(
        {
          "Course" => "NPQ for Early Years Leadership (NPQEYL)",
          "Date of birth" => "13 December 1980",
          "Do you work in a nursery?" => "No",
          "Do you work in a school, academy trust, or 16 to 19 educational setting?" => "No",
          "Do you work in early years or childcare?" => "Yes",
          "Email" => "user@example.com",
          "Full name" => "John Doe",
          "Lead provider" => "Teach First",
          "National Insurance number" => "AB123456C",
          "Ofsted registration details" => private_childcare_provider.registration_details,
          "TRN" => "1234567",
          "Where do you work?" => "England",
        },
      )
    end

    expect_page_to_have(path: "/registration/confirmation", submit_form: false) do
      expect(page).to have_text("Your initial registration is complete")
    end

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
      "kind_of_nursery" => nil,
      "lead_provider_id" => LeadProvider.find_by(name: "Teach First").id,
      "private_childcare_provider_urn" => "EY123456",
      "school_urn" => nil,
      "targeted_delivery_funding_eligibility" => false,
      "targeted_support_funding_eligibility" => false,
      "teacher_catchment" => "england",
      "teacher_catchment_country" => nil,
      "ukprn" => nil,
      "works_in_childcare" => true,
      "works_in_nursery" => false,
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
        "lead_provider_id" => LeadProvider.find_by(name: "Teach First").id.to_s,
        "national_insurance_number" => "AB123456C",
        "teacher_catchment" => "england",
        "teacher_catchment_country" => nil,
        "trn" => "1234567",
        "trn_auto_verified" => true,
        "trn_knowledge" => "yes",
        "trn_verified" => true,
        "verified_trn" => "1234567",
        "works_in_childcare" => "yes",
        "works_in_nursery" => "no",
        "works_in_school" => "no",
      },
    )
  end
end
