require "rails_helper"

RSpec.feature "Happy journeys", :with_default_nursery, :with_default_schedules, :with_eligibility_list_entries, type: :feature do
  include Helpers::JourneyAssertionHelper
  include Helpers::JourneyStepHelper
  include ApplicationHelper

  include_context "retrieve latest application data"
  include_context "with stubbed Teacher Auth OmniAuth responses"
  include_context "with stubbed Teaching Record System person API"

  before do
    create(:cohort, :next, :with_all_courses_for_provider, suffix: "b", lead_provider: LeadProvider.find_by(name: "Teach First"))
    create(:school, :eligible_with_urn_and_address)
  end

  context "with JS", :js do
    scenario("registration journey while working at private nursery") { run_scenario(js: true) }
  end

  context "without JS", :no_js do
    scenario("registration journey while working at private nursery") { run_scenario(js: false) }
  end

  def check_it_shows_the_correct_eligibility_page(js:, course:, private_childcare_provider_already_selected: false)
    complete_journey_as_far_as_choosing_a_work_setting(
      course:,
      work_setting: "Early years or childcare",
    )

    expect_page_to_have(path: "/registration/kind-of-nursery", submit_form: true) do
      page.choose("Private nursery", visible: :all)
    end

    expect_page_to_have(path: "/registration/have-ofsted-urn", submit_form: true) do
      expect(page).to have_text("Do you or your employer have an Ofsted unique reference number (URN)?")
      page.choose("Yes", visible: :all)
    end

    if private_childcare_provider_already_selected
      expect_page_to_have(path: "/registration/choose-private-childcare-provider", submit_form: false) do
        page.click_button "Continue"
      end
    else
      choose_a_private_childcare_provider(js:, urn: default_nursery.provider_urn, name: default_nursery.name)
    end

    case course
    when "Leading primary mathematics"
      expect_page_to_have(path: "/registration/ineligible-for-funding", submit_form: false) do
        expect(page).to have_text("Before you can take this NPQ, your training provider needs to check your understanding of mastery approaches to teaching maths.")
      end
    when "Special educational needs co-ordinator (SENCO)"
      expect_page_to_have(path: "/registration/senco-in-role", submit_form: false) do
        expect(page).to have_text("Do you work as a special educational needs co-ordinator (SENCO)?")
      end
    else
      expect_page_to_have(path: "/registration/ineligible-for-funding", submit_form: false) do
        expect(page).to have_text("You can go back and select the Early years leadership")
      end
    end
  end

  def run_scenario(js:)
    ineligible_courses = course_identifiers_offered_in_chosen_cohort.map { |name|
      I18n.t("course.name.#{name}")
    }.excluding("Early years leadership", "Early headship coaching offer", "Leading primary mathematics")

    ineligible_courses.each_with_index do |course, i|
      if i.zero?
        check_it_shows_the_correct_eligibility_page(js:, course:)
      else
        check_it_shows_the_correct_eligibility_page(js:, course:, private_childcare_provider_already_selected: true)
      end
    end

    # now complete a journey

    @steps_visited.clear

    complete_journey_as_far_as_choosing_a_work_setting(
      course: "Early years leadership",
      work_setting: "Early years or childcare",
    )

    expect_page_to_have(path: "/registration/kind-of-nursery", submit_form: true) do
      page.choose("Private nursery", visible: :all)
    end

    expect_page_to_have(path: "/registration/have-ofsted-urn", submit_form: true) do
      expect(page).to have_text("Do you or your employer have an Ofsted unique reference number (URN)?")
      page.choose("Yes", visible: :all)
    end

    expect_page_to_have(path: "/registration/choose-private-childcare-provider", submit_form: false) do
      page.click_button "Continue"
    end

    expect_page_to_have(path: "/registration/possible-funding", submit_form: true) do
      expect(page).to have_text("DfE scholarship funding")
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

    check_back_journey_is_correct

    check_answers_log_in_and_submit do
      expect_check_answers_page_to_have_answers(
        {
          "DfE scholarship funding" => "Eligible",
          "Cohort" => course_start_cohort_description,
          "Course" => "Early years leadership",
          "Work setting" => "Early years or childcare",
          "Provider" => "Teach First",
          "Ofsted unique reference number (URN)" => "EY487263 – searchable childcare provider – street 1, manchester",
          "Early years setting" => "Private nursery",
          "Working in England" => "Yes",
        },
      )
    end

    expect_applicant_reached_end_of_journey

    expect(retrieve_latest_application_user_data).to match(user_attributes_from_stubbed_callback_response)

    deep_compare_application_data(
      "accepted_at" => nil,
      "cohort_id" => Cohort.current.id,
      "course_id" => Course.find_by(identifier: "npq-early-years-leadership").id,
      "schedule_id" => nil,
      "ecf_id" => latest_application.ecf_id,
      "eligible_for_funding" => true,
      "employer_name" => nil,
      "employment_type" => nil,
      "employment_role" => nil,
      "funded_place" => nil,
      "funding_choice" => nil,
      "funding_eligiblity_status_code" => "funded",
      "headteacher_status" => nil,
      "itt_provider_id" => nil,
      "lead_mentor" => false,
      "lead_provider_approval_status" => "pending",
      "participant_outcome_state" => nil,
      "kind_of_nursery" => "private_nursery",
      "lead_provider_id" => LeadProvider.find_by(name: "Teach First").id,
      "notes" => nil,
      "private_childcare_provider_id" => PrivateChildcareProvider.find_by(provider_urn: "EY487263").id,
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
      "referred_by_return_to_teaching_adviser" => nil,
      "number_of_pupils" => 0,
      "tsf_primary_eligibility" => false,
      "tsf_primary_plus_eligibility" => false,
      "works_in_childcare" => true,
      "works_in_nursery" => nil,
      "works_in_school" => false,
      "work_setting" => "early_years_or_childcare",
      "senco_in_role" => nil,
      "senco_start_date" => nil,
      "on_submission_trn" => nil,
      "review_status" => nil,
      "raw_application_data" => {
        "email_template" => "eligible_scholarship_funding_not_tsf",
        "funding_eligiblity_status_code" => "funded",
        "can_share_choices" => "1",
        "check_funding" => "yes",
        "course_start_cohort" => course_start_cohort_value,
        "declared_previous_funding" => "no",
        "course_identifier" => "npq-early-years-leadership",
        "has_ofsted_urn" => "yes",
        "private_childcare_identifier" => "PrivateChildcareProvider-EY487263",
        "private_childcare_name" => js ? "" : "EY487263",
        "kind_of_nursery" => "private_nursery",
        "lead_provider_id" => LeadProvider.find_by(name: "Teach First").id.to_s,
        "pre_login_funding_eligiblity_status_code" => "funded",
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
