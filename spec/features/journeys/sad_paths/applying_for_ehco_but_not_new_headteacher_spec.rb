require "rails_helper"

RSpec.feature "Sad journeys", :with_default_schedules, type: :feature do
  include Helpers::JourneyAssertionHelper
  include Helpers::JourneyStepHelper
  include ApplicationHelper

  include_context "retrieve latest application data"
  include_context "Stub Get An Identity Omniauth Responses"

  context "when JavaScript is enabled", :js do
    scenario("applying for EHCO but not new headteacher (with JS)") { run_scenario(js: true) }
  end

  context "when JavaScript is disabled", :no_js do
    scenario("applying for EHCO but not new headteacher (without JS)") { run_scenario(js: false) }
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

    # expect(page).to be_accessible
    # TODO: aria-expanded
    expect_page_to_have(path: "/registration/teacher-catchment", axe_check: false, submit_form: true) do
      page.choose("Yes", visible: :all)
    end

    expect_page_to_have(path: "/registration/work-setting", submit_form: true) do
      page.choose("A school", visible: :all)
    end

    choose_a_school(js:, location: "manchester", name: "open")

    expect_page_to_have(path: "/registration/choose-your-npq", submit_form: true) do
      expect(page).to have_text("Which NPQ do you want to do?")
      page.choose("Early headship coaching offer", visible: :all)
    end

    expect_page_to_have(path: "/registration/npqh-status", submit_form: true) do
      expect(page).to have_selector "h2", text: "What stage are you at with the Headship NPQ?"

      page.choose "None of the above", visible: :all
    end

    expect_page_to_have(path: "/registration/ehco-unavailable", submit_form: false) do
      expect(page).to have_selector "p", text: "you need to do the Headship NPQ"

      page.click_link("Back")
    end

    expect_page_to_have(path: "/registration/npqh-status", submit_form: true) do
      expect(page).to have_selector "h2", text: "What stage are you at with the Headship NPQ?"

      page.choose "I’ve completed it", visible: :all
    end

    expect_page_to_have(path: "/registration/ehco-headteacher", submit_form: true) do
      expect(page).to have_text("Are you a headteacher?")
      page.choose("Yes", visible: :all)
    end

    expect_page_to_have(path: "/registration/ehco-new-headteacher", submit_form: true) do
      expect(page).to have_text("Are you in your first 5 years of a headship?")
      page.choose "No", visible: :all
    end

    expect_page_to_have(path: "/registration/ehco-funding-not-available", click_continue: true) do
      expect(page).to have_selector "p", text: "not eligible for the scholarship funding for"
    end

    expect_page_to_have(path: "/registration/funding-your-ehco", submit_form: true) do
      expect(page).to have_text("How are you funding the Early headship coaching offer?")
      page.choose "I am paying", visible: :all
    end

    expect_page_to_have(path: "/registration/choose-your-provider", submit_form: true) do
      expect(page).to have_text("Select your provider")
      page.choose("Teach First", visible: :all)
    end

    expect_page_to_have(path: "/registration/share-provider", submit_form: true) do
      expect(page).to have_text("Sharing your NPQ information")
      page.check("Yes, I agree to share my information", visible: :all)
    end

    expect_page_to_have(path: "/registration/check-answers", submit_button_text: "Submit", submit_form: true) do
      expect_check_answers_page_to_have_answers(
        {
          "Course start" => "In #{application_course_start_date}",
          "Workplace in England" => "Yes",
          "Work setting" => "A school",
          "Course" => "Early headship coaching offer",
          "Provider" => "Teach First",
          "Course funding" => "I am paying",
          "Workplace" => "open manchester school – street 1, manchester",
          "Headteacher" => "Yes",
          "First 5 years of headship" => "No",
          "Headship NPQ stage" => "I’ve completed it",
        },
      )
    end

    expect_applicant_reached_end_of_journey

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
      "cohort_id" => latest_application.cohort_id,
      "course_id" => Course.find_by(identifier: "npq-early-headship-coaching-offer").id,
      "schedule_id" => nil,
      "ecf_id" => latest_application.ecf_id,
      "eligible_for_funding" => false,
      "employer_name" => nil,
      "employment_type" => nil,
      "employment_role" => nil,
      "funded_place" => nil,
      "funding_choice" => "self",
      "itt_provider_id" => nil,
      "lead_mentor" => false,
      "lead_provider_approval_status" => "pending",
      "participant_outcome_state" => nil,
      "funding_eligiblity_status_code" => "not_new_headteacher_requesting_ehco",
      "headteacher_status" => "yes_over_five_years",
      "kind_of_nursery" => nil,
      "lead_provider_id" => LeadProvider.find_by(name: "Teach First").id,
      "notes" => nil,
      "private_childcare_provider_id" => nil,
      "referred_by_return_to_teaching_adviser" => nil,
      "school_id" => School.find_by(urn: "100000").id,
      "targeted_delivery_funding_eligibility" => false,
      "targeted_support_funding_eligibility" => false,
      "teacher_catchment" => "england",
      "teacher_catchment_country" => "United Kingdom of Great Britain and Northern Ireland",
      "teacher_catchment_iso_country_code" => "GBR",
      "teacher_catchment_synced_to_ecf" => false,
      "training_status" => nil,
      "ukprn" => nil,
      "primary_establishment" => false,
      "number_of_pupils" => nil,
      "tsf_primary_eligibility" => false,
      "tsf_primary_plus_eligibility" => false,
      "works_in_nursery" => nil,
      "works_in_childcare" => false,
      "works_in_school" => true,
      "work_setting" => "a_school",
      "senco_in_role" => nil,
      "senco_start_date" => nil,
      "on_submission_trn" => nil,
      "review_status" => nil,
      "raw_application_data" => {
        "can_share_choices" => "1",
        "chosen_provider" => "yes",
        "course_start" => "In #{application_course_start_date}",
        "course_start_date" => "yes",
        "course_identifier" => "npq-early-headship-coaching-offer",
        "ehco_funding_choice" => "self",
        "ehco_headteacher" => "yes",
        "ehco_new_headteacher" => "no",
        "email_template" => "not_eligible_ehco_funding",
        "funding_amount" => nil,
        "funding_eligiblity_status_code" => "not_new_headteacher_requesting_ehco",
        "institution_identifier" => "School-100000",
        "institution_location" => "manchester",
        "institution_name" => js ? "" : "open",
        "lead_provider_id" => LeadProvider.find_by(name: "Teach First").id.to_s,
        "npqh_status" => "completed_npqh",
        "submitted" => true,
        "targeted_delivery_funding_eligibility" => false,
        "teacher_catchment" => "england",
        "teacher_catchment_country" => nil,
        "works_in_school" => "yes",
        "works_in_childcare" => "no",
        "tsf_primary_eligibility" => false,
        "tsf_primary_plus_eligibility" => false,
        "work_setting" => "a_school",
      },
    )
  end
end
