require "rails_helper"

RSpec.feature "Applying for Special educational needs co-ordinator (SENCO)", :no_js, :with_cohorts, :with_default_schedules, type: :feature do
  include Helpers::JourneyAssertionHelper
  include Helpers::JourneyStepHelper
  include ApplicationHelper

  before do
    create(:school, :eligible_with_urn_and_address)
    create(:school, :local_authority_nursery_school, :with_real_urn, name: "nursery")
    create(:school, :with_real_urn, name: "ineligible school")
    provider_teach_first = LeadProvider.find_by(name: "Teach First")
    FactoryBot.create(:course_cohort, :with_provider, course: create(:course, :senco), cohort: capped_cohort, lead_provider: provider_teach_first)
    FactoryBot.create(:course_cohort, :with_provider, course: create(:course, :senco), cohort: unfunded_cohort, lead_provider: provider_teach_first)
  end

  context "when in the Autumn 2026 cohort" do
    scenario "when working as a special educational needs co-ordinator in a school" do
      complete_journey_as_far_as_choosing_a_work_setting(
        course: "Special educational needs co-ordinator (SENCO)",
        work_setting: "Secondary school (11 to 16)",
      )

      choose_a_school(js: false, name: "open")

      expect_page_to_have(path: "/registration/senco-in-role", submit_form: true) do
        expect(page).to have_selector "h1", text: "Do you work as a special educational needs co-ordinator (SENCO)?"
        page.choose "Yes", visible: :all
      end

      expect_page_to_have(path: "/registration/senco-start-date", submit_form: true) do
        expect(page).to have_selector "h1", text: "When did you become a SENCO?"
        page.fill_in "Month", with: "1"
        page.fill_in "Year", with: "2026"
      end

      expect_page_to_have(path: "/registration/funding-eligibility-senco", submit_form: false) do
        expect(page).to have_selector "h1", text: "DfE scholarship funding"
        expect(page).to have_content "Eligible"
        page.click_link "Continue to register"
      end

      choose_provider_share_information_and_check_answers(provider: "Teach First") do
        expect(page).to have_content 'funding_eligiblity_status_code: "funded"'
      end

      check_back_journey_is_correct(exclude_current_page: true)
    end

    scenario "when working as a special educational needs co-ordinator in a nursery" do
      complete_journey_as_far_as_choosing_a_work_setting(
        course: "Special educational needs co-ordinator (SENCO)",
        work_setting: "Early years or childcare",
      )

      expect_page_to_have(path: "/registration/kind-of-nursery", submit_form: true) do
        page.choose("Local authority-maintained nursery", visible: :all)
      end

      choose_a_childcare_provider(js: false, name: "nursery")

      expect_page_to_have(path: "/registration/senco-in-role", submit_form: true) do
        expect(page).to have_selector "h1", text: "Do you work as a special educational needs co-ordinator (SENCO)?"
        page.choose "Yes", visible: :all
      end

      expect_page_to_have(path: "/registration/senco-start-date", submit_form: true) do
        expect(page).to have_selector "h1", text: "When did you become a SENCO?"
        page.fill_in "Month", with: "1"
        page.fill_in "Year", with: "2026"
      end

      expect_page_to_have(path: "/registration/funding-eligibility-senco", submit_form: false) do
        expect(page).to have_selector "h1", text: "DfE scholarship funding"
        expect(page).to have_content "Eligible"
        page.click_link "Continue to register"
      end

      choose_provider_share_information_and_check_answers(provider: "Teach First") do
        expect(page).to have_content 'funding_eligiblity_status_code: "funded"'
      end

      check_back_journey_is_correct(exclude_current_page: true)
    end

    scenario "when working as a special educational needs co-ordinator in an ineligible school" do
      complete_journey_as_far_as_choosing_a_work_setting(
        course: "Special educational needs co-ordinator (SENCO)",
        work_setting: "Secondary school (11 to 16)",
      )

      choose_a_school(js: false, name: "ineligible")

      expect_page_to_have(path: "/registration/senco-in-role", submit_form: true) do
        expect(page).to have_selector "h1", text: "Do you work as a special educational needs co-ordinator (SENCO)?"
        page.choose "Yes", visible: :all
      end

      expect_page_to_have(path: "/registration/senco-start-date", submit_form: true) do
        expect(page).to have_selector "h1", text: "When did you become a SENCO?"
        page.fill_in "Month", with: "1"
        page.fill_in "Year", with: "2026"
      end

      expect_page_to_have(path: "/registration/ineligible-for-funding", submit_form: false) do
        expect(page).to have_content "You’re not eligible for scholarship funding"
        page.click_link "Continue to register"
      end

      expect_page_to_have(path: "/registration/funding-your-npq", submit_form: true) do
        page.choose "I am paying", visible: :all
      end

      choose_provider_share_information_and_check_answers(provider: "Teach First") do
        expect(page).to have_content 'funding_eligiblity_status_code: "ineligible_establishment_type"'
      end

      check_back_journey_is_correct(exclude_current_page: true)
    end

    scenario "when planning on becoming a special educational needs co-ordinator" do
      complete_journey_as_far_as_choosing_a_work_setting(
        course: "Special educational needs co-ordinator (SENCO)",
        work_setting: "Secondary school (11 to 16)",
      )

      choose_a_school(js: false, name: "open")

      expect_page_to_have(path: "/registration/senco-in-role", submit_form: true) do
        expect(page).to have_selector "h1", text: "Do you work as a special educational needs co-ordinator (SENCO)?"
        page.choose "No, but I plan to become one", visible: :all
      end

      expect_page_to_have(path: "/registration/funding-eligibility-senco", submit_form: false) do
        expect(page).to have_selector "h1", text: "DfE scholarship funding"
        expect(page).to have_content "Eligible"
        page.click_link "Continue to register"
      end

      choose_provider_share_information_and_check_answers(provider: "Teach First") do
        expect(page).to have_content 'funding_eligiblity_status_code: "funded"'
      end

      check_back_journey_is_correct(exclude_current_page: true)
    end

    scenario "when planning on becoming a special educational needs co-ordinator - ineligible school" do
      complete_journey_as_far_as_choosing_a_work_setting(
        course: "Special educational needs co-ordinator (SENCO)",
        work_setting: "Secondary school (11 to 16)",
      )

      choose_a_school(js: false, name: "ineligible")

      expect_page_to_have(path: "/registration/senco-in-role", submit_form: true) do
        expect(page).to have_selector "h1", text: "Do you work as a special educational needs co-ordinator (SENCO)?"
        page.choose "No, but I plan to become one", visible: :all
      end

      expect_page_to_have(path: "/registration/ineligible-for-funding", submit_form: false) do
        expect(page).to have_content "You’re not eligible for scholarship funding"
        page.click_link "Continue to register"
      end

      expect_page_to_have(path: "/registration/funding-your-npq", submit_form: true) do
        page.choose "I am paying", visible: :all
      end

      choose_provider_share_information_and_check_answers(provider: "Teach First") do
        expect(page).to have_content 'funding_eligiblity_status_code: "ineligible_establishment_type"'
      end

      check_back_journey_is_correct(exclude_current_page: true)
    end

    scenario "when not planning on becoming a special educational needs co-ordinator" do
      complete_journey_as_far_as_choosing_a_work_setting(
        course: "Special educational needs co-ordinator (SENCO)",
        work_setting: "Secondary school (11 to 16)",
      )

      choose_a_school(js: false, name: "open")

      expect_page_to_have(path: "/registration/senco-in-role", submit_form: true) do
        expect(page).to have_selector "h1", text: "Do you work as a special educational needs co-ordinator (SENCO)?"
        page.choose "No, I do not plan to be a SENCO", visible: :all
      end

      expect_page_to_have(path: "/registration/funding-eligibility-senco", submit_form: false) do
        expect(page).to have_selector "h1", text: "DfE scholarship funding"
        expect(page).to have_content "Eligible"
        page.click_link "Continue to register"
      end

      choose_provider_share_information_and_check_answers(provider: "Teach First") do
        expect(page).to have_content 'funding_eligiblity_status_code: "funded"'
      end

      check_back_journey_is_correct(exclude_current_page: true)
    end
  end

  scenario "when in the unfunded Spring 2026 cohort" do
    navigate_to_page(path: "/", submit_form: false, axe_check: false) do
      page.click_button("Start now")
    end

    expect_page_to_have(path: "/registration/course-start-date", submit_form: true) do
      page.choose("No, I already started in Spring", visible: :all)
    end

    expect_page_to_have(path: "/registration/choose-your-npq", submit_form: true) do
      page.choose("Special educational needs co-ordinator (SENCO)", visible: :all)
    end

    expect_page_to_have(path: "/registration/work-setting", submit_form: true) do
      page.choose("A school", visible: :all)
      page.choose("Primary school (5 to 11)", visible: :all)
    end

    choose_a_school(js: false, name: "open")

    expect_page_to_have(path: "/registration/ineligible-for-funding", submit_form: false) do
      expect(page).to have_content("You’re not eligible for scholarship funding for the Special educational needs co-ordinator (SENCO) NPQ course as you have selected the Spring 2026 cohort.")
      page.click_link("Continue to register")
    end

    expect_page_to_have(path: "/registration/funding-your-npq", submit_form: true) do
      page.choose "I am paying", visible: :all
    end

    choose_provider_share_information_and_check_answers(provider: "Teach First") do
      expect(page).to have_content 'funding_eligiblity_status_code: "unfunded_cohort"'
    end

    check_back_journey_is_correct(exclude_current_page: true)
  end

  scenario "when not working in England" do
    navigate_to_page(path: "/", submit_form: false, axe_check: false) do
      page.click_button("Start now")
    end

    expect_page_to_have(path: "/registration/course-start-date", submit_form: true) do
      page.choose("Yes", visible: :all)
    end

    expect_page_to_have(path: "/registration/check-funding", submit_form: true) do
      click_button("Check funding")
    end

    expect_page_to_have(path: "/registration/teacher-catchment", submit_form: true) do
      choose("No", visible: :all)
    end

    expect_page_to_have(path: "/registration/ineligible-for-funding", submit_form: false) do
      expect(page).to have_text("You’re not eligible for DfE scholarship funding because you do not work in England")
      click_link("Continue to register")
    end

    expect_page_to_have(path: "/registration/choose-your-npq", submit_form: true) do
      page.choose("Special educational needs co-ordinator (SENCO)", visible: :all)
    end

    expect_page_to_have(path: "/registration/work-setting", submit_form: true) do
      page.choose("A school", visible: :all)
      page.choose("Primary school (5 to 11)", visible: :all)
    end

    expect_page_to_have(path: "/registration/funding-your-npq", submit_form: true) do
      page.choose "I am paying", visible: :all
    end

    choose_provider_share_information_and_check_answers(provider: "Teach First") do
      expect(page).to have_content 'funding_eligiblity_status_code: "not_in_england"'
    end

    check_back_journey_is_correct(exclude_current_page: true)
  end

  scenario "when having declared previous funding" do
    navigate_to_page(path: "/", submit_form: false, axe_check: false) do
      page.click_button("Start now")
    end

    expect_page_to_have(path: "/registration/course-start-date", submit_form: true) do
      page.choose("Yes", visible: :all)
    end

    expect_page_to_have(path: "/registration/check-funding", submit_form: true) do
      click_button("Check funding")
    end

    expect_page_to_have(path: "/registration/teacher-catchment", submit_form: true) do
      choose("Yes", visible: :all)
    end

    expect_page_to_have(path: "/registration/choose-your-npq", submit_form: true) do
      page.choose("Special educational needs co-ordinator (SENCO)", visible: :all)
    end

    expect_page_to_have(path: "/registration/funding-history", submit_form: true) do
      page.choose("Yes", visible: :all)
    end

    expect_page_to_have(path: "/registration/ineligible-for-funding-previously-funded", submit_form: false) do
      expect(page).to have_text("You’re not eligible for DfE scholarship funding because you have received DfE funding for this course before.")
      page.click_link("Continue to register")
    end

    expect_page_to_have(path: "/registration/work-setting", submit_form: true) do
      page.choose("A school", visible: :all)
      page.choose("Primary school (5 to 11)", visible: :all)
    end

    choose_a_school(js: false, name: "open")

    expect_page_to_have(path: "/registration/funding-your-npq", submit_form: true) do
      page.choose "I am paying", visible: :all
    end

    choose_provider_share_information_and_check_answers(provider: "Teach First") do
      expect(page).to have_content 'funding_eligiblity_status_code: "previously_funded"'
    end

    check_back_journey_is_correct(exclude_current_page: true)
  end

  scenario "when continuing without DfE funding" do
    navigate_to_page(path: "/", submit_form: false, axe_check: false) do
      page.click_button("Start now")
    end

    expect_page_to_have(path: "/registration/course-start-date", submit_form: true) do
      page.choose("Yes", visible: :all)
    end

    expect_page_to_have(path: "/registration/check-funding", submit_form: true) do
      click_button("Continue without DfE funding")
    end

    expect_page_to_have(path: "/registration/choose-your-npq", submit_form: true) do
      page.choose("Special educational needs co-ordinator (SENCO)", visible: :all)
    end

    expect_page_to_have(path: "/registration/work-setting", submit_form: true) do
      page.choose("A school", visible: :all)
      page.choose("Primary school (5 to 11)", visible: :all)
    end

    choose_a_school(js: false, name: "open")

    choose_provider_share_information_and_check_answers(provider: "Teach First") do
      expect(page).to have_summary_item("DfE scholarship funding", "Not eligible")
      expect(page).to have_content 'funding_eligiblity_status_code: "not_in_england"' # TODO: will be fixed in NPQ-3974
    end

    check_back_journey_is_correct(exclude_current_page: true)
  end

  scenario "when the work setting is 'Another setting'" do
    complete_journey_as_far_as_choosing_a_work_setting(
      course: "Special educational needs co-ordinator (SENCO)",
      work_setting: "Another setting",
    )

    expect_page_to_have(path: "/registration/senco-in-role", submit_form: true) do
      page.choose "Yes", visible: :all
    end

    expect_page_to_have(path: "/registration/senco-start-date", submit_form: true) do
      page.fill_in "Month", with: "1"
      page.fill_in "Year", with: "2026"
    end

    expect_page_to_have(path: "/registration/your-employment", submit_form: true) do
      expect(page).to have_text("How are you employed?")
      page.choose("In an independent hospital education organisation", visible: :all)
    end

    expect_page_to_have(path: "/registration/your-employer", submit_form: true) do
      page.fill_in "What organisation are you employed by?", with: "Big company"
    end

    expect_page_to_have(path: "/registration/possible-funding", submit_form: true) do
      expect(page).to have_content "In review"
    end

    choose_provider_share_information_and_check_answers(provider: "Teach First") do
      expect(page).to have_summary_item("DfE scholarship funding", "Not eligible")
      expect(page).to have_content 'funding_eligiblity_status_code: "subject_to_review"'
    end

    check_back_journey_is_correct(exclude_current_page: true)
  end

  scenario "when the work setting is 'Another setting' and continuing without DfE funding" do
    navigate_to_page(path: "/", submit_form: false, axe_check: false) do
      page.click_button("Start now")
    end

    expect_page_to_have(path: "/registration/course-start-date", submit_form: true) do
      page.choose("Yes", visible: :all)
    end

    expect_page_to_have(path: "/registration/check-funding", submit_form: true) do
      click_button("Continue without DfE funding")
    end

    expect_page_to_have(path: "/registration/choose-your-npq", submit_form: true) do
      page.choose("Special educational needs co-ordinator (SENCO)", visible: :all)
    end

    expect_page_to_have(path: "/registration/work-setting", submit_form: true) do
      page.choose("Another setting", visible: :all)
    end

    expect_page_to_have(path: "/registration/your-employment", submit_form: true) do
      expect(page).to have_text("How are you employed?")
      page.choose("In an independent hospital education organisation", visible: :all)
    end

    expect_page_to_have(path: "/registration/your-employer", submit_form: true) do
      page.fill_in "What organisation are you employed by?", with: "Big company"
    end

    choose_provider_share_information_and_check_answers(provider: "Teach First") do
      expect(page).to have_summary_item("DfE scholarship funding", "Not eligible")
      expect(page).to have_content 'funding_eligiblity_status_code: "not_in_england"' # TODO: will be fixed in NPQ-3974
    end

    check_back_journey_is_correct(exclude_current_page: true)
  end

  scenario "when the work setting is 'Other'" do
    complete_journey_as_far_as_choosing_a_work_setting(
      course: "Special educational needs co-ordinator (SENCO)",
      work_setting: "Other",
    )

    expect_page_to_have(path: "/registration/senco-in-role", submit_form: true) do
      page.choose "Yes", visible: :all
    end

    expect_page_to_have(path: "/registration/senco-start-date", submit_form: true) do
      page.fill_in "Month", with: "1"
      page.fill_in "Year", with: "2026"
    end

    expect_page_to_have(path: "/registration/referred-by-return-to-teaching-adviser", submit_form: true) do
      page.choose("Yes", visible: :all)
    end

    expect_page_to_have(path: "/registration/possible-funding", submit_form: true) do
      expect(page).to have_content "In review"
    end

    choose_provider_share_information_and_check_answers(provider: "Teach First") do
      expect(page).to have_content 'funding_eligiblity_status_code: "referred_by_return_to_teaching_adviser"'
    end

    check_back_journey_is_correct(exclude_current_page: true)
  end

  scenario "when the work setting is 'Other' and continuing without DfE funding" do
    navigate_to_page(path: "/", submit_form: false, axe_check: false) do
      page.click_button("Start now")
    end

    expect_page_to_have(path: "/registration/course-start-date", submit_form: true) do
      page.choose("Yes", visible: :all)
    end

    expect_page_to_have(path: "/registration/check-funding", submit_form: true) do
      click_button("Continue without DfE funding")
    end

    expect_page_to_have(path: "/registration/choose-your-npq", submit_form: true) do
      page.choose("Special educational needs co-ordinator (SENCO)", visible: :all)
    end

    expect_page_to_have(path: "/registration/work-setting", submit_form: true) do
      page.choose("Other", visible: :all)
    end

    choose_provider_share_information_and_check_answers(provider: "Teach First") do
      expect(page).to have_content 'funding_eligiblity_status_code: "not_in_england"' # TODO: will be fixed in NPQ-3974
    end

    check_back_journey_is_correct(exclude_current_page: true)
  end
end
