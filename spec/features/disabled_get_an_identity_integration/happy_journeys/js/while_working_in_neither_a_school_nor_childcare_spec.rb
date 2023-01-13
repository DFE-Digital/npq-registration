require "rails_helper"

RSpec.feature "Happy journeys", type: :feature do
  include Helpers::JourneyHelper
  include Helpers::JourneyAssertionHelper

  include_context "retrieve latest application data"
  include_context "Disable Get An Identity integration"

  scenario "registration journey while working in neither a school nor childcare" do
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

    expect_page_to_have(path: "/registration/work-setting", submit_form: true) do
      page.choose("Other", visible: :all)
    end

    expect_page_to_have(path: "/registration/contact-details", submit_form: true) do
      expect(page).to have_text("What’s your email address?")

      page.fill_in "What’s your email address?", with: "user@example.com"
    end

    expect_page_to_have(path: "/registration/confirm-email", submit_form: true) do
      expect(page).to have_text("Confirm your email address")
      expect(page).to have_text("user@example.com")
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

    School.create!(urn: 100_000, name: "open manchester school", address_1: "street 1", town: "manchester", establishment_status_code: "1")

    expect_page_to_have(path: "/registration/your-employment", submit_form: true) do
      expect(page).to have_text("How are you employed?")
      page.choose("In a hospital school", visible: :all)
    end

    expect_page_to_have(path: "/registration/your-role", submit_form: true) do
      page.fill_in "What is your role?", with: "Trainer"
    end

    expect_page_to_have(path: "/registration/your-employer", submit_form: true) do
      page.fill_in "What organisation are you employed by?", with: "Big company"
    end

    expect_page_to_have(path: "/registration/choose-your-npq", submit_form: true) do
      expect(page).to have_text("What are you applying for?")
      page.choose("NPQ for Early Years Leadership (NPQEYL)", visible: :all)
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
          "Email" => "user@example.com",
          "Course" => "NPQ for Early Years Leadership (NPQEYL)",
          "Employment type" => "In a hospital school",
          "Employer" => "Big company",
          "Role" => "Trainer",
          "What setting do you work in?" => "Other",
          "Lead provider" => "Teach First",
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
      "flipper_admin_access" => false,
      "full_name" => "John Doe",
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
      "course_id" => Course.find_by_code(code: :NPQEYL).id,
      "ecf_id" => nil,
      "eligible_for_funding" => false,
      "employer_name" => "Big company",
      "employment_role" => "Trainer",
      "employment_type" => "hospital_school",
      "funding_choice" => nil,
      "funding_eligiblity_status_code" => "no_institution",
      "headteacher_status" => nil,
      "kind_of_nursery" => nil,
      "lead_provider_id" => LeadProvider.find_by(name: "Teach First").id,
      "private_childcare_provider_urn" => nil,
      "school_urn" => nil,
      "targeted_delivery_funding_eligibility" => false,
      "targeted_support_funding_eligibility" => false,
      "teacher_catchment" => "england",
      "teacher_catchment_country" => nil,
      "teacher_catchment_synced_to_ecf" => false,
      "ukprn" => nil,
      "works_in_childcare" => false,
      "works_in_nursery" => nil,
      "works_in_school" => false,
      "work_setting" => "other",
      "raw_application_data" => {
        "active_alert" => false,
        "can_share_choices" => "1",
        "chosen_provider" => "yes",
        "confirmed_email" => "user@example.com",
        "course_id" => "9",
        "date_of_birth" => "1980-12-13",
        "email" => "user@example.com",
        "employment_type" => "hospital_school",
        "employer_name" => "Big company",
        "employment_role" => "Trainer",
        "full_name" => "John Doe",
        "lead_provider_id" => "9",
        "national_insurance_number" => "AB123456C",
        "teacher_catchment" => "england",
        "teacher_catchment_country" => nil,
        "trn" => "1234567",
        "trn_auto_verified" => true,
        "trn_verified" => true,
        "verified_trn" => "1234567",
        "works_in_childcare" => "no",
        "works_in_school" => "no",
        "work_setting" => "other",
      },
    )
  end
end
