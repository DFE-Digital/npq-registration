require "rails_helper"

RSpec.feature "Happy journeys", type: :feature do
  include Helpers::JourneyHelper
  include Helpers::JourneyAssertionHelper

  include_context "retrieve latest application data"
  include_context "stub course ecf to identifier mappings"
  include_context "Enable Get An Identity integration"

  scenario "registration journey when previously funded" do
    stub_participant_validation_request

    navigate_to_page(path: "/", submit_form: false, axe_check: false) do
      expect(page).to have_text("Before you start")
      page.click_link("Start now")
    end

    expect_page_to_have(path: "/registration/teacher-reference-number", submit_form: true) do
      page.choose("Yes", visible: :all)
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
      page.choose("Early years or childcare", visible: :all)
    end

    School.create!(urn: 100_000, name: "open manchester school", address_1: "street 1", town: "manchester", establishment_status_code: "1")

    expect_page_to_have(path: "/registration/nursery-type", submit_form: true) do
      expect(page).to have_text("Which early years setting do you work in?")
      page.choose("Private nursery", visible: :all)
    end

    expect_page_to_have(path: "/registration/have-ofsted-urn", submit_form: true) do
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

    expect_page_to_have(path: "/registration/choose-private-childcare-provider", submit_form: true) do
      expect(page).to have_text("Enter your or your employer’s URN")

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

    expect_page_to_have(path: "/registration/choose-your-npq", submit_form: true) do
      expect(page).to have_text("What are you applying for?")
      page.choose("NPQ for Early Years Leadership (NPQEYL)", visible: :all)
    end

    expect_page_to_have(path: "/registration/ineligible-for-funding", submit_form: false) do
      expect(page).to have_text("DfE scholarship funding is not available")
      expect(page).to have_text("You can only receive scholarship funding to study this NPQ with one provider")
      expect(page).to have_text("If you have previously failed or withdrawn from this course")
      expect(page).to have_text("You can go back and select a different NPQ")

      page.click_link("Back")
    end

    expect_page_to_have(path: "/registration/choose-your-npq", submit_form: true) do
      page.choose("Early Headship Coaching Offer", visible: :all)
    end

    expect_page_to_have(path: "/registration/about-ehco", submit_form: false) do
      expect(page).to have_text("Early Headship Coaching Offer")

      page.click_link("Continue")
    end

    expect_page_to_have(path: "/registration/npqh-status", submit_form: true) do
      expect(page).to have_text("Are you studying for, or have you completed an NPQ for Headship (NPQH)?")
      page.choose("I have completed an NPQH", visible: :all)
    end

    expect_page_to_have(path: "/registration/aso-headteacher", submit_form: true) do
      expect(page).to have_text("Are you a headteacher?")
      page.choose("Yes", visible: :all)
    end

    expect_page_to_have(path: "/registration/aso-new-headteacher", submit_form: true) do
      expect(page).to have_text("Are you in your first 5 years of a headship?")
      page.choose("Yes", visible: :all)
    end

    expect_page_to_have(path: "/registration/aso-previously-funded", submit_form: false) do
      expect(page).to have_text("DfE scholarship funding is not available")
      expect(page).to have_text("You can only receive scholarship funding to study this offer with one provider")
      expect(page).to have_text("If you have previously withdrawn from this offer")

      page.click_link("Continue")
    end

    expect_page_to_have(path: "/registration/funding-your-aso", submit_form: true) do
      expect(page).to have_text("How is the Early Headship Coaching Offer being paid for?")
      page.choose "I am paying", visible: :all
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

          "Course" => "Early Headship Coaching Offer",
          "How is your EHCO being paid for?" => "I am paying",
          "Have you completed an NPQH?" => "I have completed an NPQH",
          "Are you a headteacher?" => "Yes",
          "Are you in your first 5 years of a headship?" => "Yes",
          # "Do you work in a nursery?" => "Yes",
          "What setting do you work in?" => "Early years or childcare",
          "Lead provider" => "Teach First",
          "Ofsted registration details" => "EY123456 - searchable childcare provider",
          "Type of nursery" => "Private nursery",
          "Where do you work?" => "England",
        },
      )
    end

    expect_page_to_have(path: "/registration/confirmation", submit_form: false) do
      expect(page).to have_text("Your initial registration is complete")
    end

    expect(retrieve_latest_application_user_data).to eq(
      "active_alert" => nil,
      "admin" => false,
      "date_of_birth" => "1980-12-13",
      "ecf_id" => nil,
      "email" => "user@example.com",
      "flipper_admin_access" => false,
      "full_name" => "John Doe",
      "national_insurance_number" => nil,
      "otp_expires_at" => nil,
      "otp_hash" => nil,
      "raw_tra_provider_data" => stubbed_callback_response_as_json,
      "provider" => "tra_openid_connect",
      "trn_auto_verified" => false,
      "trn_verified" => true,
      "trn" => "1234567",
      "uid" => user_uid,
    )

    expect(retrieve_latest_application_data).to eq(
      "cohort" => 2021,
      "course_id" => Course.find_by_code(code: :EHCO).id,
      "ecf_id" => nil,
      "eligible_for_funding" => false,
      "employer_name" => nil,
      "employment_type" => nil,
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
      "teacher_catchment_synced_to_ecf" => false,
      "ukprn" => nil,
      "works_in_childcare" => true,
      "works_in_nursery" => true,
      "works_in_school" => false,
      "work_setting" => "early_years_or_childcare",
      "raw_application_data" => {
        "aso_funding_choice" => "self",
        "aso_headteacher" => "yes",
        "aso_new_headteacher" => "yes",
        "can_share_choices" => "1",
        "chosen_provider" => "yes",
        "course_id" => Course.find_by_code(code: :EHCO).id.to_s,
        "has_ofsted_urn" => "yes",
        "institution_identifier" => "PrivateChildcareProvider-EY123456",
        "institution_name" => "",
        "kind_of_nursery" => "private_nursery",
        "lead_provider_id" => LeadProvider.find_by(name: "Teach First").id.to_s,
        "npqh_status" => "completed_npqh",
        "teacher_catchment" => "england",
        "teacher_catchment_country" => nil,
        "trn_knowledge" => "yes",
        "works_in_childcare" => "yes",
        "works_in_nursery" => "yes",
        "works_in_school" => "no",
        "work_setting" => "early_years_or_childcare",
      },
    )
  end
end
