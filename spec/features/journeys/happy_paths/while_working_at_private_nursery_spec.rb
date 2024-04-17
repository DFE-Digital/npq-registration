require "rails_helper"

RSpec.feature "Happy journeys", type: :feature do
  include Helpers::JourneyAssertionHelper
  include Helpers::JourneyStepHelper
  include ApplicationHelper

  include_context "retrieve latest application data"
  include_context "Stub previously funding check for all courses" do
    let(:api_call_trn) { user_trn }
  end
  include_context "Stub Get An Identity Omniauth Responses"

  context "when JavaScript is enabled", :js do
    scenario("registration journey while working at private nursery (with JS)") { run_scenario(js: true) }
  end

  context "when JavaScript is disabled", :no_js do
    scenario("registration journey while working at private nursery (without JS)") { run_scenario(js: false) }
  end

  def run_scenario(js:)
    stub_participant_validation_request

    navigate_to_page(path: "/", submit_form: false, axe_check: false) do
      expect(page).to have_text("Before you start")
      page.click_button("Start now")
    end

    expect(page).not_to have_content("Before you start")

    expect_page_to_have(path: "/registration/course-start-date", submit_form: true) do
      expect(page).to have_text("NPQ start dates are usually every February and October.")
      page.choose("Yes", visible: :all)
    end

    expect_page_to_have(path: "/registration/provider-check", submit_form: true) do
      expect(page).to have_text("Have you chosen an NPQ and provider?")
      page.choose("Yes", visible: :all)
    end

    # TODO: aria-expanded
    expect_page_to_have(path: "/registration/teacher-catchment", axe_check: false, submit_form: true) do
      page.choose("Yes", visible: :all)
    end

    expect_page_to_have(path: "/registration/work-setting", submit_form: true) do
      page.choose("Early years or childcare", visible: :all)
    end

    School.create!(urn: 100_000, name: "open manchester school", address_1: "street 1", town: "manchester", establishment_status_code: "1")

    expect_page_to_have(path: "/registration/kind-of-nursery", submit_form: true) do
      expect(page).to have_text("Which early years setting do you work in?")
      page.choose("Private nursery", visible: :all)
    end

    expect_page_to_have(path: "/registration/have-ofsted-urn", submit_form: true) do
      expect(page).to have_text("Do you or your employer have an Ofsted unique reference number (URN)?")
      page.choose("Yes", visible: :all)
    end

    choose_a_private_childcare_provider(js:, urn: "EY123456", name: "searchable childcare provider")

    eyl_course = ["Early years leadership"]
    ehco_course = ["Early headship coaching offer"]
    npqlpm_course = ["Leading primary mathematics"]

    ineligible_courses_list = Questionnaires::ChooseYourNpq.new.options.map(&:value)

    ineligible_courses = ineligible_courses_list.map { |name|
      I18n.t("course.name.#{name}")
    } - eyl_course - ehco_course - npqlpm_course

    ineligible_courses.each do |course|
      expect_page_to_have(path: "/registration/choose-your-npq", submit_form: true) do
        expect(page).to have_text("Which NPQ do you want to do?")
        page.choose(course, visible: :all)
      end

      expect(page).to have_text("You can go back and select the Early years leadership") unless course == "Leading primary mathematics"
      expect(page).to have_text("Before you can take this NPQ, your training provider needs to check your understanding of mastery approaches to teaching maths.") if course == "Leading primary mathematics"
      page.click_link("Back")
    end

    expect_page_to_have(path: "/registration/choose-your-npq", submit_form: true) do
      expect(page).to have_text("Which NPQ do you want to do?")
      page.choose("Early years leadership", visible: :all)
    end

    expect_page_to_have(path: "/registration/possible-funding", submit_form: true) do
      expect(page).to have_text("Funding")
      expect(page).to have_text("eligible for scholarship funding")
    end

    expect_page_to_have(path: "/registration/choose-your-provider", submit_form: true) do
      expect(page).to have_text("Select your provider")
      page.choose("Teach First", visible: :all)
    end

    expect_page_to_have(path: "/registration/share-provider", submit_form: true) do
      expect(page).to have_text("Sharing your NPQ information")
      page.check("Yes, I agree to share my information", visible: :all)
    end

    allow(ApplicationSubmissionJob).to receive(:perform_later).with(anything)

    expect_page_to_have(path: "/registration/check-answers", submit_form: true, submit_button_text: "Submit") do
      expect_check_answers_page_to_have_answers(
        {
          "Course start" => "Before #{application_course_start_date}",
          "Course" => "Early years leadership",
          "Work setting" => "Early years or childcare",
          "Provider" => "Teach First",
          "Ofsted unique reference number (URN)" => "EY123456 – searchable childcare provider – street 1, manchester",
          "Early years setting" => "Private nursery",
          "Workplace in England" => "Yes",
        },
      )
    end

    expect_applicant_reached_end_of_journey

    expect(retrieve_latest_application_user_data).to match(
      "active_alert" => false,
      "date_of_birth" => "1980-12-13",
      "ecf_id" => nil,
      "email" => "user@example.com",
      "full_name" => "John Doe",
      "get_an_identity_id_synced_to_ecf" => false,
      "national_insurance_number" => nil,
      "notify_user_for_future_reg" => false,
      "provider" => "tra_openid_connect",
      "raw_tra_provider_data" => stubbed_callback_response_as_json,
      "trn" => "1234567",
      "trn_auto_verified" => false,
      "trn_lookup_status" => "Found",
      "trn_verified" => true,
      "uid" => user_uid,
    )

    deep_compare_application_data(
      "cohort_id" => nil,
      "course_id" => Course.find_by(identifier: "npq-early-years-leadership").id,
      "ecf_id" => nil,
      "eligible_for_funding" => true,

      "employer_name" => nil,
      "employment_type" => nil,
      "employment_role" => nil,
      "funding_choice" => nil,
      "funding_eligiblity_status_code" => "funded",
      "headteacher_status" => nil,
      "itt_provider_id" => nil,
      "lead_mentor" => false,
      "lead_provider_approval_status" => nil,
      "participant_outcome_state" => nil,
      "kind_of_nursery" => "private_nursery",
      "lead_provider_id" => LeadProvider.find_by(name: "Teach First").id,
      "notes" => nil,
      "private_childcare_provider_id" => PrivateChildcareProvider.find_by(provider_urn: "EY123456").id,
      "school_id" => nil,
      "targeted_delivery_funding_eligibility" => false,
      "targeted_support_funding_eligibility" => false,
      "teacher_catchment" => "england",
      "teacher_catchment_country" => nil,
      "teacher_catchment_iso_country_code" => nil,
      "teacher_catchment_synced_to_ecf" => false,
      "ukprn" => nil,
      "primary_establishment" => false,
      "number_of_pupils" => 0,
      "tsf_primary_eligibility" => false,
      "tsf_primary_plus_eligibility" => false,
      "works_in_childcare" => true,
      "works_in_nursery" => nil,
      "works_in_school" => false,
      "work_setting" => "early_years_or_childcare",
      "raw_application_data" => {
        "targeted_delivery_funding_eligibility" => false,
        "email_template" => "eligible_scholarship_funding_not_tsf",
        "funding_eligiblity_status_code" => "funded",
        "tsf_primary_eligibility" => false,
        "tsf_primary_plus_eligibility" => false,
        "can_share_choices" => "1",
        "chosen_provider" => "yes",
        "course_start" => "Before #{application_course_start_date}",
        "course_start_date" => "yes",
        "course_identifier" => "npq-early-years-leadership",
        "has_ofsted_urn" => "yes",
        "funding_amount" => nil,
        "institution_identifier" => "PrivateChildcareProvider-EY123456",
        "institution_name" => js ? "" : "EY123456",
        "kind_of_nursery" => "private_nursery",
        "lead_provider_id" => "9",
        "submitted" => true,
        "teacher_catchment" => "england",
        "teacher_catchment_country" => nil,
        "works_in_childcare" => "yes",
        "works_in_school" => "no",
        "work_setting" => "early_years_or_childcare",
      },
    )
  end
end
