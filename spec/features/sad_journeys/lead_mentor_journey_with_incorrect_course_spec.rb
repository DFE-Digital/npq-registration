require "rails_helper"

RSpec.feature "Sad journeys", type: :feature do
  include Helpers::JourneyAssertionHelper

  include_context "retrieve latest application data"
  include_context "Stub previously funding check for all courses" do
    let(:api_call_trn) { user_trn }
  end
  include_context "Stub Get An Identity Omniauth Responses"

  xscenario "registration journey when choosing lead mentor journey and approved ITT provider but picking the wrong course" do
    stub_participant_validation_request

    navigate_to_page(path: "/", submit_form: false, axe_check: false) do
      expect(page).to have_text("Before you start")
      page.click_button("Start now")
    end

    expect(page).not_to have_content("Before you start")

    expect_page_to_have(path: "/registration/provider-check", submit_form: true) do
      expect(page).to have_text("Have you chosen an NPQ and provider?")
      page.choose("Yes", visible: :all)
    end

    expect_page_to_have(path: "/registration/teacher-catchment", axe_check: false, submit_form: true) do
      page.choose("Yes", visible: :all)
    end

    expect_page_to_have(path: "/registration/work-setting", submit_form: true) do
      page.choose("Other", visible: :all)
    end

    expect_page_to_have(path: "/registration/your-employment", submit_form: true) do
      expect(page).to have_text("How are you employed?")
      page.choose("As a lead mentor for an accredited initial teacher training (ITT) provider", visible: :all)
    end

    approved_itt_provider_legal_name = ::IttProvider.currently_approved.sample.legal_name

    expect_page_to_have(path: "/registration/itt-provider", submit_form: true) do
      expect(page).to have_text("Enter the name of the ITT provider you are working with")
      page.fill_in("Enter the name of the ITT provider you are working with", with: approved_itt_provider_legal_name)
      page.click_button("Continue")
    end

    expect_page_to_have(path: "/registration/choose-your-npq", submit_form: true) do
      expect(page).to have_text("Which NPQ do you want to do?")
      page.choose("Senior leadership", visible: :all)
    end

    expect_page_to_have(path: "/registration/ineligible-for-funding", submit_form: false) do
      expect(page).to have_text("Funding")
      expect(page).to have_text("such as state-funded schools")
      expect(page).to have_text("This means that you would need to pay for the course another way")

      page.click_link("Continue")
    end

    expect_page_to_have(path: "/registration/funding-your-npq", submit_form: true) do
      expect(page).to have_text("How are you funding your course?")
      page.choose "I am paying", visible: :all
    end

    expect_page_to_have(path: "/registration/choose-your-provider", submit_form: true) do
      expect(page).to have_text("Select your provider")
      page.choose("Church of England", visible: :all)
    end

    expect_page_to_have(path: "/registration/share-provider", submit_form: true) do
      expect(page).to have_text("Sharing your NPQ information")
      page.check("Yes, I agree my information can be shared", visible: :all)
    end

    allow(ApplicationSubmissionJob).to receive(:perform_later).with(anything)

    expect_page_to_have(path: "/registration/check-answers", submit_button_text: "Submit", submit_form: true) do
      expect_check_answers_page_to_have_answers(
        {
          "Course" => "Senior leadership",
          "Employment type" => "As a lead mentor for an accredited initial teacher training (ITT) provider",
          "ITT Provider" => approved_itt_provider_legal_name,
          "Provider" => "Church of England",
          "Work setting" => "Other",
          "Workplace in England" => "Yes",
          "Course funding" => "I am paying",
        },
      )
    end

    expect_applicant_reached_end_of_journey

    User.last.tap do |user|
      expect(user.email).to eql("user@example.com")
      expect(user.full_name).to eql("John Doe")
      expect(user.trn).to eql("1234567")
      expect(user.trn_verified).to be_truthy
      expect(user.trn_auto_verified).to be_falsey
      expect(user.date_of_birth).to eql(Date.new(1980, 12, 13))
      expect(user.national_insurance_number).to eq(nil)
      expect(user.applications.count).to be(1)

      user.applications.first.tap do |application|
        expect(application.eligible_for_funding).to eq(false)
        expect(application.targeted_delivery_funding_eligibility).to eq(false)
        expect(application.work_setting).to eql("other")
        expect(application.raw_application_data["employment_type"])
          .to eql("lead_mentor_for_accredited_itt_provider")
      end
    end

    if User.last.applications.count == 1
      navigate_to_page(path: "/accounts/user_registrations/#{User.last.applications.last.id}", axe_check: false, submit_form: false) do
        expect(page).to have_text("Church of England")
        expect(page).to have_text("Your NPQ registration")
      end
    else
      navigate_to_page(path: "/account", axe_check: false, submit_form: false) do
        expect(page).to have_text("Church of England")
        expect(page).to have_text("Your NPQ registration")
      end
    end

    visit "/registration/share-provider"

    expect_page_to_have(path: "/", axe_check: false, submit_form: false) do
      expect(page).to have_content("Before you start")
    end

    expect(retrieve_latest_application_user_data).to match(
      "active_alert" => false,
      "admin" => false,
      "date_of_birth" => "1980-12-13",
      "ecf_id" => nil,
      "email" => "user@example.com",
      "full_name" => "John Doe",
      "get_an_identity_id_synced_to_ecf" => false,
      "national_insurance_number" => nil,
      "otp_expires_at" => nil,
      "otp_hash" => nil,
      "provider" => "tra_openid_connect",
      "raw_tra_provider_data" => stubbed_callback_response_as_json,
      "super_admin" => false,
      "trn" => "1234567",
      "trn_auto_verified" => false,
      "trn_lookup_status" => "Found",
      "trn_verified" => true,
      "uid" => user_uid,
    )

    deep_compare_application_data(
      "cohort_id" => nil,
      "course_id" => Course.find_by(identifier: "npq-senior-leadership").id,
      "ecf_id" => nil,
      "eligible_for_funding" => false,
      "employer_name" => nil,
      "employment_type" => "lead_mentor_for_accredited_itt_provider",
      "employment_role" => nil,
      "funding_choice" => "self",
      "funding_eligiblity_status_code" => "not_lead_mentor_course",
      "kind_of_nursery" => nil,
      "headteacher_status" => nil,
      "lead_provider_id" => LeadProvider.find_by(name: "Church of England").id,
      "private_childcare_provider_id" => nil,
      "school_id" => nil,
      "targeted_delivery_funding_eligibility" => false,
      "teacher_catchment" => "england",
      "teacher_catchment_country" => nil,
      "teacher_catchment_synced_to_ecf" => false,
      "ukprn" => nil,
      "primary_establishment" => false,
      "number_of_pupils" => 0,
      "tsf_primary_eligibility" => false,
      "tsf_primary_plus_eligibility" => false,
      "works_in_childcare" => false,
      "works_in_nursery" => nil,
      "works_in_school" => false,
      "work_setting" => "other",
      "lead_mentor" => true,
      "lead_provider_approval_status" => nil,
      "participant_outcome_state" => nil,
      "itt_provider_id" => approved_itt_provider_legal_name.present? && IttProvider.find_by(legal_name: approved_itt_provider_legal_name).id,
      "raw_application_data" => {
        "can_share_choices" => "1",
        "chosen_provider" => "yes",
        "course_identifier" => "npq-senior-leadership",
        "email_template" => "itt_leader_wrong_course",
        "funding_amount" => nil,
        "employment_type" => "lead_mentor_for_accredited_itt_provider",
        "funding" => "self",
        "funding_eligiblity_status_code" => "not_lead_mentor_course",
        "itt_provider" => approved_itt_provider_legal_name,
        "lead_provider_id" => "3",
        "submitted" => true,
        "targeted_delivery_funding_eligibility" => false,
        "teacher_catchment" => "england",
        "teacher_catchment_country" => nil,
        "tsf_primary_eligibility" => false,
        "tsf_primary_plus_eligibility" => false,
        "work_setting" => "other",
        "works_in_childcare" => "no",
        "works_in_school" => "no",
      },
    )
  end
end
