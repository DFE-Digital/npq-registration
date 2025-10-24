require "rails_helper"

RSpec.feature "Happy journeys", :with_default_schedules, type: :feature do
  include Helpers::JourneyAssertionHelper
  include Helpers::JourneyStepHelper
  include ApplicationHelper

  include_context "retrieve latest application data"
  include_context "Stub Get An Identity Omniauth Responses"

  context "when JavaScript is enabled", :js do
    scenario("registration journey when choosing lead mentor journey and approved ITT provider (with JS)") { run_scenario(js: true) }
  end

  context "when JavaScript is disabled", :no_js do
    scenario("registration journey when choosing lead mentor journey and approved ITT provider (without JS)") { run_scenario(js: false) }
  end

  def run_scenario(js:)
    stub_participant_validation_request

    navigate_to_page(path: "/", submit_form: false, axe_check: false) do
      expect(page).to have_text("Before you start")
      page.click_button("Start now")
    end

    expect(page).not_to have_content("Before you start")

    expect_page_to_have(path: "/registration/course-start-date", submit_form: true) do
      expect(page).to have_text(I18n.t("helpers.hint.registration_wizard.course_start_date_one"))
      page.choose("Yes", visible: :all)
    end

    expect_page_to_have(path: "/registration/provider-check", submit_form: true) do
      expect(page).to have_text("Have you chosen an NPQ and provider?")
      page.choose("Yes", visible: :all)
    end

    expect_page_to_have(path: "/registration/teacher-catchment", axe_check: false, submit_form: true) do
      page.choose("Yes", visible: :all)
    end

    expect_page_to_have(path: "/registration/work-setting", submit_form: true) do
      page.choose("Another setting", visible: :all)
    end

    expect_page_to_have(path: "/registration/your-employment", submit_form: true) do
      expect(page).to have_text("How are you employed?")
      page.choose("As a lead mentor for an accredited initial teacher training (ITT) provider", visible: :all)
    end

    approved_itt_provider_legal_name = ::IttProvider.currently_approved.sample.legal_name

    choose_an_itt_provider(js:, name: approved_itt_provider_legal_name)

    expect_page_to_have(path: "/registration/choose-your-npq", submit_form: true) do
      expect(page).to have_text("Which NPQ do you want to do?")
      page.choose("Leading teacher development", visible: :all)
    end

    expect_page_to_have(path: "/registration/possible-funding", submit_form: true) do
      expect(page).to have_text("Funding")
      expect(page).to have_text("You’re eligible for scholarship funding for the")
    end

    expect_page_to_have(path: "/registration/choose-your-provider", submit_form: true) do
      expect(page).to have_text("Select your provider")
      page.choose("Church of England", visible: :all)
    end

    expect_page_to_have(path: "/registration/share-provider", submit_form: true) do
      expect(page).to have_text("Sharing your NPQ information")
      page.check("Yes, I agree to share my information", visible: :all)
    end

    expect_page_to_have(path: "/registration/check-answers", submit_button_text: "Submit", submit_form: true) do
      expect_check_answers_page_to_have_answers(
        {

          "Course start" => "In #{application_course_start_date}",
          "Course" => "Leading teacher development",
          "Employment type" => "As a lead mentor for an accredited initial teacher training (ITT) provider",
          "ITT provider" => approved_itt_provider_legal_name,
          "Provider" => "Church of England",
          "Work setting" => "Another setting",
          "Workplace in England" => "Yes",
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
      expect(user.national_insurance_number).to be_nil
      expect(user.applications.count).to be(1)

      user.applications.first.tap do |application|
        expect(application.eligible_for_funding).to be(true)
        expect(application.targeted_delivery_funding_eligibility).to be(false)
        expect(application.work_setting).to eql("another_setting")
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

    expect(retrieve_latest_application_user_data).to match(user_attributes_from_stubbed_callback_response.merge(
                                                             "active_alert" => false,
                                                             "archived_email" => nil,
                                                             "archived_at" => nil,
                                                             "ecf_id" => latest_application_user.ecf_id,
                                                             "get_an_identity_id_synced_to_ecf" => false,
                                                             "national_insurance_number" => nil,
                                                             "notify_user_for_future_reg" => false,
                                                             "trn_auto_verified" => false,
                                                             "trn_verified" => true,
                                                           ))

    deep_compare_application_data(
      "accepted_at" => nil,
      "cohort_id" => Cohort.current.id,
      "course_id" => Course.find_by(identifier: "npq-leading-teaching-development").id,
      "schedule_id" => nil,
      "ecf_id" => latest_application.ecf_id,
      "eligible_for_funding" => true,
      "employer_name" => nil,
      "employment_type" => "lead_mentor_for_accredited_itt_provider",
      "employment_role" => nil,
      "funded_place" => nil,
      "funding_choice" => nil,
      "funding_eligiblity_status_code" => "funded",
      "kind_of_nursery" => nil,
      "headteacher_status" => nil,
      "lead_provider_id" => LeadProvider.find_by(name: "Church of England").id,
      "notes" => nil,
      "private_childcare_provider_id" => nil,
      "referred_by_return_to_teaching_adviser" => nil,
      "school_id" => nil,
      "targeted_delivery_funding_eligibility" => false,
      "targeted_support_funding_eligibility" => false,
      "teacher_catchment" => "england",
      "teacher_catchment_country" => "United Kingdom of Great Britain and Northern Ireland",
      "teacher_catchment_iso_country_code" => "GBR",
      "teacher_catchment_synced_to_ecf" => false,
      "training_status" => nil,
      "ukprn" => nil,
      "primary_establishment" => false,
      "number_of_pupils" => 0,
      "tsf_primary_eligibility" => false,
      "tsf_primary_plus_eligibility" => false,
      "works_in_childcare" => false,
      "works_in_nursery" => nil,
      "works_in_school" => false,
      "work_setting" => "another_setting",
      "lead_mentor" => true,
      "lead_provider_approval_status" => "pending",
      "participant_outcome_state" => nil,
      "itt_provider_id" => approved_itt_provider_legal_name.present? && IttProvider.find_by(legal_name: approved_itt_provider_legal_name).id,
      "senco_in_role" => nil,
      "senco_start_date" => nil,
      "on_submission_trn" => nil,
      "review_status" => nil,
      "raw_application_data" => {
        "targeted_delivery_funding_eligibility" => false,
        "email_template" => "eligible_scholarship_funding_not_tsf",
        "funding_eligiblity_status_code" => "funded",
        "funding_amount" => nil,
        "tsf_primary_eligibility" => false,
        "tsf_primary_plus_eligibility" => false,
        "can_share_choices" => "1",
        "chosen_provider" => "yes",
        "course_start" => "In #{application_course_start_date}",
        "course_start_date" => "yes",
        "course_identifier" => "npq-leading-teaching-development",
        "employment_type" => "lead_mentor_for_accredited_itt_provider",
        "itt_provider" => approved_itt_provider_legal_name,
        "lead_provider_id" => "3",
        "submitted" => true,
        "teacher_catchment" => "england",
        "teacher_catchment_country" => nil,
        "work_setting" => "another_setting",
        "works_in_childcare" => "no",
        "works_in_school" => "no",
      },
    )
  end
end
