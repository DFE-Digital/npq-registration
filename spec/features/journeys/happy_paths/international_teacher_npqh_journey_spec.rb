require "rails_helper"

RSpec.feature "Happy journeys", :rack_test_driver, :with_default_schedules, type: :feature do
  include Helpers::JourneyAssertionHelper
  include Helpers::JourneyStepHelper
  include ApplicationHelper

  include_context "retrieve latest application data"
  include_context "Stub Get An Identity Omniauth Responses"

  context "when JavaScript is enabled or disabled" do
    scenario("international teacher NPQH journey", :js, :no_js) { run_scenario(js: false) }
  end

  def run_scenario(*)
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
      page.choose("No", visible: :all)
    end

    expect_page_to_have(path: "/registration/work-setting", submit_form: true) do
      page.choose("A school", visible: :all)
    end

    expect_page_to_have(path: "/registration/choose-your-npq", submit_form: true) do
      expect(page).to have_text("Which NPQ do you want to do?")
      expect(page).not_to have_text("Additional Support Offer for new headteachers")
      page.choose("Headship", visible: :all)
    end

    expect_page_to_have(path: "/registration/ineligible-for-funding", submit_form: false) do
      expect(page).to have_text("Funding")
      expect(page).to have_text("you do not work in England")
      expect(page).to have_text("This means that you would need to pay for the course another way")

      page.click_link("Continue")
    end

    expect_page_to_have(path: "/registration/funding-your-npq", submit_form: true) do
      expect(page).to have_text("How are you funding your course?")
      page.choose("My workplace is covering the cost", visible: :all)
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
          "Workplace in England" => "No",
          "Work setting" => "A school",
          "Course" => "Headship",
          "Provider" => "Teach First",
          "Course funding" => "My workplace is covering the cost",
        },
      )
    end

    expect_applicant_reached_end_of_journey

    if User.last.applications.count == 1
      navigate_to_page(path: "/accounts/user_registrations/#{User.last.applications.last.id}", axe_check: false, submit_form: false) do
        expect(page).to have_text("Teach First")
        expect(page).to have_text("Headship")
      end
    else
      navigate_to_page(path: "/account", axe_check: false, submit_form: false) do
        expect(page).to have_text("Teach First")
        expect(page).to have_text("Headship")
      end
    end

    visit "/registration/share-provider"
    expect(page).to have_current_path("/")

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
      "course_id" => Course.find_by(identifier: "npq-headship").id,
      "schedule_id" => nil,
      "ecf_id" => latest_application.ecf_id,
      "eligible_for_funding" => false,
      "employer_name" => nil,
      "employment_type" => nil,
      "employment_role" => nil,
      "funded_place" => nil,
      "funding_choice" => "school",
      "itt_provider_id" => nil,
      "lead_mentor" => false,
      "lead_provider_approval_status" => "pending",
      "participant_outcome_state" => nil,
      "funding_eligiblity_status_code" => "not_in_england",
      "headteacher_status" => nil,
      "kind_of_nursery" => nil,
      "lead_provider_id" => LeadProvider.find_by(name: "Teach First").id,
      "notes" => nil,
      "private_childcare_provider_id" => nil,
      "referred_by_return_to_teaching_adviser" => nil,
      "school_id" => nil,
      "targeted_delivery_funding_eligibility" => false,
      "targeted_support_funding_eligibility" => false,
      "teacher_catchment" => "another",
      "teacher_catchment_country" => nil,
      "teacher_catchment_iso_country_code" => nil,
      "teacher_catchment_synced_to_ecf" => false,
      "training_status" => nil,
      "ukprn" => nil,
      "primary_establishment" => false,
      "number_of_pupils" => 0,
      "tsf_primary_eligibility" => false,
      "tsf_primary_plus_eligibility" => false,
      "works_in_childcare" => false,
      "works_in_nursery" => nil,
      "works_in_school" => true,
      "work_setting" => "a_school",
      "senco_in_role" => nil,
      "senco_start_date" => nil,
      "on_submission_trn" => nil,
      "review_status" => nil,
      "raw_application_data" => {
        "email_template" => "not_england_wrong_catchment",
        "lead_provider_id" => LeadProvider.find_by(name: "Teach First").id.to_s,
        "submitted" => true,
        "works_in_school" => "yes",
        "works_in_childcare" => "no",
        "work_setting" => "a_school",
        "can_share_choices" => "1",
        "chosen_provider" => "yes",
        "course_start" => "In #{application_course_start_date}",
        "course_start_date" => "yes",
        "course_identifier" => "npq-headship",
        "funding" => "school",
        "funding_amount" => nil,
        "targeted_delivery_funding_eligibility" => false,
        "teacher_catchment" => "another",
        "teacher_catchment_country" => nil,
        "tsf_primary_eligibility" => false,
        "tsf_primary_plus_eligibility" => false,
        "funding_eligiblity_status_code" => "not_in_england",
      },
    )
  end
end
