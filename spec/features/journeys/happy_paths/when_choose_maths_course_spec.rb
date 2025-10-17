require "rails_helper"

RSpec.feature "Happy journeys", :with_default_schedules, :with_eligibility_list_entries, type: :feature do
  include Helpers::JourneyAssertionHelper
  include Helpers::JourneyStepHelper
  include ApplicationHelper

  include_context "with default schedules"
  include_context "retrieve latest application data"
  include_context "Stub Get An Identity Omniauth Responses"

  context "when JavaScript is enabled", :js do
    scenario("registration journey when choosing Leading primary mathematics journey (with JS)") { run_scenario(js: true) }
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
      page.choose("Yes", visible: :all)
    end

    expect_page_to_have(path: "/registration/work-setting", submit_form: true) do
      page.choose("A school", visible: :all)
    end

    School.create!(urn: 100_000,
                   name: "open manchester school",
                   address_1: "street 1", town: "manchester",
                   establishment_status_code: "1",
                   establishment_type_code: 1,
                   number_of_pupils: 150,
                   phase_name: "Primary")
    School.create!(urn: 100_001, name: "closed manchester school", address_1: "street 2", town: "manchester", establishment_status_code: "2")
    School.create!(urn: 100_002, name: "open newcastle school", address_1: "street 3", town: "newcastle", establishment_status_code: "1")

    expect_page_to_have(path: "/registration/find-school", submit_form: true) do
      page.fill_in I18n.t("helpers.title.registration_wizard.institution_location"), with: "manchester"
    end

    expect_page_to_have(path: "/registration/choose-school", submit_form: true) do
      expect(page).to have_html(I18n.t("helpers.hint.registration_wizard.choose_school_html"))

      within ".npq-js-reveal" do
        page.fill_in "What is the name of your workplace?", with: "open"
      end

      expect(page).to have_content("open manchester school")

      page.find("#school-picker__option--0").click
      page.click_button("Continue")
    end

    expect_page_to_have(path: "/registration/choose-your-npq", submit_form: true) do
      expect(page).to have_text("Which NPQ do you want to do?")
      page.choose("Leading primary mathematics", visible: :all)
    end

    expect_page_to_have(path: "/registration/maths-eligibility-teaching-for-mastery", submit_form: true) do
      expect(page).to have_text("Have you taken at least one year of the primary maths Teaching for Mastery programme?")
      page.choose("Yes", visible: :all)
    end

    expect_page_to_have(path: "/registration/funding-eligibility-maths", submit_form: true) do
      expect(page).to have_text("Funding")
      expect(page).to have_text("You’re eligible for scholarship funding for the Leading primary mathematics NPQ, but this does not guarantee a funded place is available.")
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
          "Workplace in England" => "Yes",
          "Work setting" => "A school",
          "Workplace" => "open manchester school – street 1, manchester",
          "Course" => "Leading primary mathematics",
          "Completed one year of the primary maths Teaching for Mastery programme" => "Yes",
          "Provider" => "Church of England",
        },
      )
    end

    expect_page_to_have(path: "/accounts/user_registrations/#{latest_application.id}?success=true", submit_form: false) do
      expect(page).to have_text("Registration successfully submitted")
      expect(page).to have_text("Leading primary mathematics NPQ")
    end

    expect(User.count).to be(1)

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
      end
    end

    expect(page).to have_text("Church of England")
    expect(page).to have_text("Leading primary mathematics NPQ")

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
      "course_id" => Course.find_by(identifier: "npq-leading-primary-mathematics").id,
      "schedule_id" => nil,
      "ecf_id" => latest_application.ecf_id,
      "eligible_for_funding" => true,
      "employer_name" => nil,
      "employment_type" => nil,
      "employment_role" => nil,
      "funded_place" => nil,
      "funding_choice" => nil,
      "funding_eligiblity_status_code" => "funded",
      "kind_of_nursery" => nil,
      "headteacher_status" => nil,
      "itt_provider_id" => nil,
      "lead_mentor" => false,
      "lead_provider_approval_status" => "pending",
      "participant_outcome_state" => nil,
      "lead_provider_id" => LeadProvider.find_by(name: "Church of England").id,
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
      "primary_establishment" => true,
      "number_of_pupils" => 150,
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
        "can_share_choices" => "1",
        "chosen_provider" => "yes",
        "course_start" => "In #{application_course_start_date}",
        "course_start_date" => "yes",
        "course_identifier" => "npq-leading-primary-mathematics",
        "email_template" => "eligible_scholarship_funding_not_tsf",
        "funding_eligiblity_status_code" => "funded",
        "institution_identifier" => "School-100000",
        "institution_location" => "manchester",
        "institution_name" => "",
        "lead_provider_id" => "3",
        "maths_eligibility_teaching_for_mastery" => "yes",
        "maths_understanding" => true,
        "submitted" => true,
        "targeted_delivery_funding_eligibility" => false,
        "teacher_catchment" => "england",
        "teacher_catchment_country" => nil,
        "works_in_school" => "yes",
        "works_in_childcare" => "no",
        "funding_amount" => nil,
        "tsf_primary_eligibility" => false,
        "tsf_primary_plus_eligibility" => false,
        "work_setting" => "a_school",
      },
    )
  end
end
