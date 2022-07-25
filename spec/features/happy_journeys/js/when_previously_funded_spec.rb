require "rails_helper"

RSpec.feature "Happy journeys", type: :feature do
  include Helpers::JourneyHelper
  include Helpers::JourneyAssertionHelper

  include_context "retrieve latest application data"
  include_context "stub course ecf to identifier mappings"

  scenario "registration journey when previously funded" do
    stub_participant_validation_request

    navigate_to_page("/", submit_form: false, axe_check: false) do
      expect(page).to have_text("Before you start")
      page.click_link("Start now")
    end

    now_i_should_be_on_page("/registration/provider-check") do
      expect(page).to have_text("Have you already chosen an NPQ and provider?")
      page.choose("Yes", visible: :all)
    end

    # TODO: aria-expanded
    now_i_should_be_on_page("/registration/teacher-catchment", axe_check: false) do
      page.choose("England", visible: :all)
    end

    now_i_should_be_on_page("/registration/work-in-school") do
      page.choose("No", visible: :all)
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

    now_i_should_be_on_page("/registration/work-in-childcare") do
      expect(page).to have_text("Do you work in early years or childcare?")
      page.choose("Yes", visible: :all)
    end

    now_i_should_be_on_page("/registration/work-in-nursery") do
      expect(page).to have_text("Do you work in a nursery?")
      page.choose("Yes", visible: :all)
    end

    now_i_should_be_on_page("/registration/kind-of-nursery") do
      expect(page).to have_text("What kind of nursery do you work in?")
      page.choose("Private nursery", visible: :all)
    end

    now_i_should_be_on_page("/registration/have-ofsted-urn") do
      expect(page).to have_text("Do you or your employer have an Ofsted unique reference number (URN)?")
      page.choose("Yes", visible: :all)
    end

    PrivateChildcareProvider.create!(
      provider_urn: "EY123456",
      provider_name: "searchable childcare provider",
      address_1: "street 1",
      town: "manchester",
      early_years_individual_registers: %w[CCR VCR EYR],
    )

    now_i_should_be_on_page("/registration/choose-private-childcare-provider") do
      expect(page).to have_text("Enter your or your employer's URN")

      within ".npq-js-reveal" do
        page.fill_in "private-childcare-provider-picker", with: "EY123"
      end

      expect(page).to have_content("EY123456 - searchable childcare provider - street 1, manchester")

      page.find("#private-childcare-provider-picker__option--0").click
    end

    %w[npq-early-headship-coaching-offer npq-early-years-leadership].each do |identifier|
      stub_request(:get, "https://ecf-app.gov.uk/api/v1/npq-funding/1234567?npq_course_identifier=#{identifier}")
        .with(
          headers: {
            "Authorization" => "Bearer ECFAPPBEARERTOKEN",
          },
        )
        .to_return(
          status: 200,
          body: previously_funded_response(true),
          headers: {
            "Content-Type" => "application/vnd.api+json",
          },
        )
    end

    now_i_should_be_on_page("/registration/choose-your-npq") do
      expect(page).to have_text("What are you applying for?")
      page.choose("NPQ for Early Years Leadership (NPQEYL)", visible: :all)
    end

    now_i_should_be_on_page("/registration/ineligible-for-funding", submit_form: false) do
      expect(page).to have_text("DfE scholarship funding is not available")
      expect(page).to have_text("You can only receive scholarship funding to study this NPQ with one provider")
      expect(page).to have_text("If you have previously failed or withdrawn from this course")
      expect(page).to have_text("You can go back and select a different NPQ")

      page.click_link("Back")
    end

    now_i_should_be_on_page("/registration/choose-your-npq") do
      page.choose("Early Headship Coaching Offer", visible: :all)
    end

    now_i_should_be_on_page("/registration/about-ehco", submit_form: false) do
      expect(page).to have_text("Early Headship Coaching Offer")

      page.click_link("Continue")
    end

    now_i_should_be_on_page("/registration/npqh-status") do
      expect(page).to have_text("Are you studying for, or have you completed an NPQ for Headship (NPQH)?")
      page.choose("I have completed an NPQH", visible: :all)
    end

    now_i_should_be_on_page("/registration/aso-headteacher") do
      expect(page).to have_text("Are you a headteacher?")
      page.choose("Yes", visible: :all)
    end

    now_i_should_be_on_page("/registration/aso-new-headteacher") do
      expect(page).to have_text("Are you in your first 5 years of a headship?")
      page.choose("Yes", visible: :all)
    end

    now_i_should_be_on_page("/registration/aso-previously-funded", submit_form: false) do
      expect(page).to have_text("DfE scholarship funding is not available")
      expect(page).to have_text("You can only receive scholarship funding to study this offer with one provider")
      expect(page).to have_text("If you have previously withdrawn from this offer")

      page.click_link("Continue")
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
      expect_check_answers_page_to_have_answers(
        {
          "Full name" => "John Doe",
          "TRN" => "1234567",
          "Date of birth" => "13 December 1980",
          "National Insurance number" => "AB123456C",
          "Email" => "user@example.com",
          "Course" => "Early Headship Coaching Offer",
          "How is your EHCO being paid for?" => "I am paying",
          "Have you completed an NPQH?" => "I have completed an NPQH",
          "Are you a headteacher?" => "Yes",
          "Are you in your first 5 years of a headship?" => "Yes",
          "Do you work in a nursery?" => "Yes",
          "Do you work in a school, academy trust, or 16 to 19 educational setting?" => "No",
          "Do you work in early years or childcare?" => "Yes",
          "Lead provider" => "Teach First",
          "Ofsted registration details" => "EY123456 - searchable childcare provider",
          "Type of nursery" => "Private nursery",
          "Where do you work?" => "England",
        },
      )
    end

    now_i_should_be_on_page("/registration/confirmation", submit_form: false) do
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
      "cohort" => 2021,
      "course_id" => Course.find_by_code(code: :EHCO).id,
      "ecf_id" => nil,
      "eligible_for_funding" => false,
      "employer_name" => nil,
      "employment_role" => nil,
      "funding_choice" => "self",
      "funding_eligiblity_status_code" => "previously_funded",
      "headteacher_status" => "yes_in_first_five_years",
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
        "aso_funding_choice" => "self",
        "aso_headteacher" => "yes",
        "aso_new_headteacher" => "yes",
        "can_share_choices" => "1",
        "chosen_provider" => "yes",
        "confirmed_email" => "user@example.com",
        "course_id" => Course.find_by_code(code: :EHCO).id.to_s,
        "date_of_birth" => "1980-12-13",
        "email" => "user@example.com",
        "full_name" => "John Doe",
        "has_ofsted_urn" => "yes",
        "institution_identifier" => "PrivateChildcareProvider-EY123456",
        "institution_name" => "",
        "kind_of_nursery" => "private_nursery",
        "lead_provider_id" => LeadProvider.find_by(name: "Teach First").id.to_s,
        "national_insurance_number" => "AB123456C",
        "npqh_status" => "completed_npqh",
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
