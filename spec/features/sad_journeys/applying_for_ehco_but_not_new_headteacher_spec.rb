require "rails_helper"

RSpec.feature "Happy journeys", type: :feature do
  include Helpers::JourneyHelper
  include Helpers::JourneyAssertionHelper

  include_context "retrieve latest application data"
  include_context "stub course ecf to identifier mappings"

  scenario "applying for EHCO but not new headteacher" do
    stub_participant_validation_request

    navigate_to_page("/", submit_form: false, axe_check: false) do
      expect(page).to have_text("Before you start")
      page.click_link("Start now")
    end

    now_i_should_be_on_page("/registration/provider-check") do
      expect(page).to have_text("Have you already chosen an NPQ and provider?")
      page.choose("Yes", visible: :all)
    end

    # expect(page).to be_axe_clean
    # TODO: aria-expanded
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

      page.fill_in "Teacher reference number (TRN)", with: "1234567"
      page.fill_in "Full name", with: "John Doe"
      page.fill_in "Day", with: "13"
      page.fill_in "Month", with: "12"
      page.fill_in "Year", with: "1980"
      page.fill_in "National Insurance number", with: "AB123456C"
    end

    School.create!(urn: 100_000, name: "open manchester school", address_1: "street 1", town: "manchester", establishment_status_code: "1")

    now_i_should_be_on_page("/registration/find-school") do
      expect(page).to have_text("Where is your school, college or academy trust?")
      page.fill_in "Workplace location", with: "manchester"
    end

    now_i_should_be_on_page("/registration/choose-school") do
      expect(page).to have_text("Choose your workplace")
      expect(page).to have_text("Choose from schools, trusts and 16 to 19 educational settings located in manchester")

      within ".npq-js-reveal" do
        page.fill_in "Enter the name of your workplace", with: "open"
      end

      expect(page).to have_content("open manchester school")

      page.find("#school-picker__option--0").click
      page.click_button("Continue")
    end

    now_i_should_be_on_page("/registration/choose-your-npq") do
      expect(page).to have_text("What are you applying for?")
      page.choose("Early Headship Coaching Offer", visible: :all)
    end

    now_i_should_be_on_page("/registration/about-ehco", submit_form: false) do
      expect(page).to have_selector "h1", text: "Early Headship Coaching Offer"

      page.click_link("Continue")
    end

    now_i_should_be_on_page("/registration/npqh-status") do
      expect(page).to have_selector "h1", text: "Are you studying for, or have you completed an NPQ for Headship (NPQH)?"

      page.choose "None of the above", visible: :all
    end

    now_i_should_be_on_page("/registration/aso-unavailable", submit_form: false) do
      expect(page).to have_selector "h1", text: "You cannot register for the Early Headship Coaching Offer"

      page.click_link("Back")
    end

    now_i_should_be_on_page("/registration/npqh-status") do
      expect(page).to have_selector "h1", text: "Are you studying for, or have you completed an NPQ for Headship (NPQH)?"

      page.choose "I have completed an NPQH", visible: :all
    end

    now_i_should_be_on_page("/registration/aso-headteacher") do
      expect(page).to have_text("Are you a headteacher?")
      page.choose("Yes", visible: :all)
    end

    now_i_should_be_on_page("/registration/aso-new-headteacher") do
      expect(page).to have_text("Are you in your first 5 years of a headship?")
      page.choose "No", visible: :all
    end

    now_i_should_be_on_page("/registration/aso-funding-not-available", submit_form: false) do
      expect(page).to have_selector "h1", text: "DfE scholarship funding is not available"

      page.click_button("Continue")
    end

    now_i_should_be_on_page("/registration/funding-your-aso") do
      expect(page).to have_text("How is the Early Headship Coaching Offer being paid for?")
      page.choose "I am paying", visible: :all
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
          "Email" => "user@example.com",
          "Course" => "Early Headship Coaching Offer",
          "Lead provider" => "Teach First",
          "How is your EHCO being paid for?" => "I am paying",
          "Workplace" => "open manchester school",
          "Are you a headteacher?" => "Yes",
          "Are you in your first 5 years of a headship?" => "No",
          "Have you completed an NPQH?" => "I have completed an NPQH",
          "National Insurance number" => "AB123456C",
        },
      )
    end

    now_i_should_be_on_page("/registration/confirmation", submit_form: false) do
      expect(page).to have_text("Your initial registration is complete")
      expect(page).to_not have_text("The Early Headship Coaching Offer is a package of structured face-to-face support for new headteachers.")
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
      "cohort" => 2021,
      "course_id" => Course.find_by_code(code: :EHCO).id,
      "ecf_id" => nil,
      "eligible_for_funding" => false,
      "employer_name" => nil,
      "employment_role" => nil,
      "funding_choice" => "self",
      "funding_eligiblity_status_code" => "ineligible_establishment_type",
      "headteacher_status" => "yes_over_five_years",
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
        "aso_funding_choice" => "self",
        "aso_headteacher" => "yes",
        "aso_new_headteacher" => "no",
        "can_share_choices" => "1",
        "chosen_provider" => "yes",
        "confirmed_email" => "user@example.com",
        "course_id" => Course.find_by_code(code: :EHCO).id.to_s,
        "date_of_birth" => "1980-12-13",
        "email" => "user@example.com",
        "full_name" => "John Doe",
        "institution_identifier" => "School-100000",
        "institution_location" => "manchester",
        "institution_name" => "",
        "lead_provider_id" => "9",
        "national_insurance_number" => "AB123456C",
        "npqh_status" => "completed_npqh",
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
