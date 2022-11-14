require "rails_helper"

RSpec.feature "Happy journeys", type: :feature do
  include Helpers::JourneyHelper
  include Helpers::JourneyAssertionHelper

  include_context "retrieve latest application data"
  include_context "Enable Get An Identity integration"

  scenario "registration journey changing do you work in a school from no to yes" do
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
      page.choose("Other", visible: :all)
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
      page.choose("NPQ for Senior Leadership (NPQSL)", visible: :all)
    end

    expect_page_to_have(path: "/registration/choose-your-provider", submit_form: true) do
      expect(page).to have_text("Select your provider")
      page.choose("Teach First", visible: :all)
    end

    expect_page_to_have(path: "/registration/share-provider", submit_form: true) do
      expect(page).to have_text("Sharing your NPQ information")
      page.check("Yes, I agree my information can be shared", visible: :all)
    end

    expect_page_to_have(path: "/registration/check-answers", submit_form: false) do
      expect_check_answers_page_to_have_answers(
        {

          "Course" => "NPQ for Senior Leadership (NPQSL)",
          "What setting do you work in?" => "Other",
          "Employment type" => "In a hospital school",
          "Employer" => "Big company",
          "Lead provider" => "Teach First",
          "Role" => "Trainer",
          "Where do you work?" => "England",
        },
      )

      page.click_link("Change", href: "/registration/work-setting/change")
    end

    expect_page_to_have(path: "/registration/work-setting/change", submit_form: true) do
      page.choose("A school", visible: :all)
    end

    expect_page_to_have(path: "/registration/find-school", submit_form: true) do
      page.fill_in "Where is your workplace located?", with: "manchester"
    end

    expect_page_to_have(path: "/registration/choose-school", submit_form: true) do
      expect(page).to have_text("Search for schools or 16 to 19 educational settings located in manchester. If you work for a trust, enter one of their schools.")
      within ".npq-js-reveal" do
        page.fill_in "What’s the name of your workplace?", with: "open"
      end

      expect(page).to have_content("open manchester school")
      page.find("#school-picker__option--0").click
    end

    stub_request(:get, "https://ecf-app.gov.uk/api/v1/npq-funding/1234567?npq_course_identifier=npq-senior-leadership")
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

    expect_page_to_have(path: "/registration/choose-your-npq", submit_form: true) do
      expect(page).to have_text("What are you applying for?")
      page.choose("NPQ for Senior Leadership (NPQSL)", visible: :all)
    end

    expect_page_to_have(path: "/registration/ineligible-for-funding", submit_form: false) do
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

    expect_page_to_have(path: "/registration/funding-your-npq", submit_form: true) do
      expect(page).to have_text("How is your course being paid for?")
      page.choose "My workplace is covering the cost", visible: :all
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

          "Course" => "NPQ for Senior Leadership (NPQSL)",
          "How is your NPQ being paid for?" => "My workplace is covering the cost",
          "What setting do you work in?" => "A school",
          "Workplace" => "open manchester school",
          "Lead provider" => "Teach First",
          "Where do you work?" => "England",
        },
      )
    end

    expect_page_to_have(path: "/registration/confirmation", submit_form: false) do
      expect(page).to have_text("Your initial registration is complete")
      expect(page).to_not have_text("The Early Headship Coaching Offer is a package of structured face-to-face support for new headteachers.")
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
      "provider" => "tra_openid_connect",
      "raw_tra_provider_data" => stubbed_callback_response_as_json,
      "trn" => "1234567",
      "trn_auto_verified" => false,
      "trn_verified" => true,
      "uid" => user_uid,
    )

    expect(retrieve_latest_application_data).to eq(
      "cohort" => 2022,
      "course_id" => Course.find_by_code(code: :NPQSL).id,
      "ecf_id" => nil,
      "eligible_for_funding" => false,
      "employer_name" => nil,
      "employment_type" => nil,
      "employment_role" => nil,
      "funding_choice" => "school",
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
      "teacher_catchment_synced_to_ecf" => false,
      "ukprn" => nil,
      "works_in_childcare" => false,
      "works_in_nursery" => false,
      "works_in_school" => true,
      "work_setting" => "a_school",
      "raw_application_data" => {
        "can_share_choices" => "1",
        "chosen_provider" => "yes",
        "course_id" => Course.find_by_code(code: :NPQSL).id.to_s,
        "employment_type" => "hospital_school",
        "employer_name" => "Big company",
        "employment_role" => "Trainer",
        "funding" => "school",
        "institution_identifier" => "School-100000",
        "institution_location" => "manchester",
        "institution_name" => "",
        "lead_provider_id" => LeadProvider.find_by(name: "Teach First").id.to_s,
        "teacher_catchment" => "england",
        "teacher_catchment_country" => nil,
        "trn_knowledge" => "yes",
        "work_setting" => "a_school",
        "works_in_childcare" => "no",
        "works_in_school" => "yes",
      },
    )
  end
end
