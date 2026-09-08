require "rails_helper"

RSpec.feature "Applying for Early headship coaching offer (EHCO)", :no_js, :with_cohorts, :with_default_schedules, type: :feature do
  include Helpers::JourneyAssertionHelper
  include Helpers::JourneyStepHelper
  include ApplicationHelper

  before { create(:school, :eligible_with_urn_and_address) }

  context "when in the Autumn 2026 cohort" do
    before do
      complete_journey_as_far_as_choosing_a_work_setting(
        course: "Early headship coaching offer",
        work_setting: "Secondary school (11 to 16)",
      )

      choose_a_school(js: false, name: "open")
    end

    scenario "when not doing the Headship NPQ" do
      expect_page_to_have(path: "/registration/npqh-status", submit_form: true) do
        expect(page).to have_selector "h1", text: "Eligibility for the Early headship coaching offer"
        expect(page).to have_content "To be eligible for the Early headship coaching offer you need to do the Headship NPQ."
        expect(page).to have_selector "h2", text: "What stage are you at with the Headship NPQ?"
        page.choose "None of the above", visible: :all
      end

      expect_page_to_have(path: "/registration/ehco-unavailable", submit_form: false) do
        expect(page).to have_selector "p", text: "you need to do the Headship NPQ"
        expect(page).not_to have_link("Continue to register")
      end

      check_back_journey_is_correct(exclude_current_page: true)
    end

    scenario "when doing the Headship NPQ" do
      expect_page_to_have(path: "/registration/npqh-status", submit_form: true) do
        page.choose "I’m doing it", visible: :all
      end

      expect_page_to_have(path: "/registration/ehco-new-headteacher", submit_form: true) do
        expect(page).to have_selector "h1", text: "Are you a headteacher in your first 5 years of a headship?"
        page.choose "Yes", visible: :all
      end

      expect_page_to_have(path: "/registration/ehco-possible-funding", click_continue: false) do
        expect(page).to have_selector "h1", text: "DfE scholarship funding"
        expect(page).to have_selector "p", text: "You’re eligible for DfE scholarship funding for the Early headship" \
          " coaching offer because you are a headteacher in your first 5 years of headship."
        expect(page).to have_content "Being eligible for funding does not guarantee you'll get a funded place." \
          " Your provider will confirm if one is available when you apply to them."
        click_link "Continue to register"
      end

      choose_provider_share_information_and_check_answers(provider: "Teach First") do
        expect(page).to have_content 'funding_eligiblity_status_code: "funded"'
      end

      check_back_journey_is_correct(exclude_current_page: true)
    end

    scenario "when having completed the Headship NPQ" do
      expect_page_to_have(path: "/registration/npqh-status", submit_form: true) do
        page.choose "I’ve completed it", visible: :all
      end

      expect_page_to_have(path: "/registration/ehco-new-headteacher", submit_form: true) do
        expect(page).to have_selector "h1", text: "Are you a headteacher in your first 5 years of a headship?"
        page.choose "Yes", visible: :all
      end

      expect_page_to_have(path: "/registration/ehco-possible-funding", click_continue: false) do
        click_link "Continue to register"
      end

      choose_provider_share_information_and_check_answers(provider: "Teach First") do
        expect(page).to have_content 'funding_eligiblity_status_code: "funded"'
      end

      check_back_journey_is_correct(exclude_current_page: true)
    end

    scenario "when not a headteacher not in first 5 years of headship" do
      expect_page_to_have(path: "/registration/npqh-status", submit_form: true) do
        page.choose "I’ve completed it", visible: :all
      end

      expect_page_to_have(path: "/registration/ehco-new-headteacher", submit_form: true) do
        expect(page).to have_selector "h1", text: "Are you a headteacher in your first 5 years of a headship?"
        page.choose "No", visible: :all
      end

      expect_page_to_have(path: "/registration/ineligible-for-funding", click_continue: false) do
        expect(page).to have_selector "h1", text: "DfE scholarship funding"
        expect(page).to have_selector "p", text: "You’re not eligible for DfE scholarship funding because you are not a headteacher in your first 5 years of headship."
        expect(page).to have_link("learn more about who is eligible for funding")
        click_link "Continue to register"
      end

      expect_page_to_have(path: "/registration/funding-your-ehco", submit_form: true) do
        page.choose "I am paying", visible: :all
      end

      choose_provider_share_information_and_check_answers(provider: "Teach First") do
        expect(page).to have_content 'funding_eligiblity_status_code: "not_new_headteacher_requesting_ehco"'
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
      page.choose("Early headship coaching offer", visible: :all)
    end

    expect_page_to_have(path: "/registration/work-setting", submit_form: true) do
      page.choose("A school", visible: :all)
      page.choose("Primary school (5 to 11)", visible: :all)
    end

    choose_a_school(js: false, name: "open")

    expect_page_to_have(path: "/registration/npqh-status", submit_form: true) do
      page.choose "I’m doing it", visible: :all
    end

    expect_page_to_have(path: "/registration/ehco-new-headteacher", submit_form: true) do
      page.choose "Yes", visible: :all
    end

    expect_page_to_have(path: "/registration/ineligible-for-funding", submit_form: false) do
      expect(page).to have_content("You’re not eligible for scholarship funding for the Early headship coaching offer course as you have selected the Spring 2026 cohort.")
      page.click_link("Continue to register")
    end

    expect_page_to_have(path: "/registration/funding-your-ehco", submit_form: true) do
      page.choose "I am paying", visible: :all
    end

    choose_provider_share_information_and_check_answers(provider: "LLSE") do
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
      page.choose("Early headship coaching offer", visible: :all)
    end

    expect_page_to_have(path: "/registration/work-setting", submit_form: true) do
      page.choose("A school", visible: :all)
      page.choose("Primary school (5 to 11)", visible: :all)
    end

    expect_page_to_have(path: "/registration/npqh-status", submit_form: true) do
      page.choose "I’m doing it", visible: :all
    end

    expect_page_to_have(path: "/registration/ehco-new-headteacher", submit_form: true) do
      page.choose "Yes", visible: :all
    end

    expect_page_to_have(path: "/registration/funding-your-ehco", submit_form: true) do
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
      page.choose("Early headship coaching offer", visible: :all)
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

    expect_page_to_have(path: "/registration/npqh-status", submit_form: true) do
      page.choose "I’m doing it", visible: :all
    end

    expect_page_to_have(path: "/registration/ehco-new-headteacher", submit_form: true) do
      page.choose "Yes", visible: :all
    end

    expect_page_to_have(path: "/registration/funding-your-ehco", submit_form: true) do
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
      page.choose("Early headship coaching offer", visible: :all)
    end

    expect_page_to_have(path: "/registration/work-setting", submit_form: true) do
      page.choose("A school", visible: :all)
      page.choose("Primary school (5 to 11)", visible: :all)
    end

    expect_page_to_have(path: "/registration/npqh-status", submit_form: true) do
      page.choose "I’m doing it", visible: :all
    end

    expect_page_to_have(path: "/registration/ehco-new-headteacher", submit_form: true) do
      page.choose "Yes", visible: :all
    end

    choose_provider_share_information_and_check_answers(provider: "Teach First") do
      expect(page).to have_summary_item("DfE scholarship funding", "Not eligible")
      expect(page).to have_content 'funding_eligiblity_status_code: "requested_no_funding"'
    end

    check_back_journey_is_correct(exclude_current_page: true)
  end

  scenario "when the work setting is 'Another setting'" do
    complete_journey_as_far_as_choosing_a_work_setting(
      course: "Early headship coaching offer",
      work_setting: "Another setting",
    )

    expect_page_to_have(path: "/registration/npqh-status", submit_form: true) do
      page.choose "I’m doing it", visible: :all
    end

    expect_page_to_have(path: "/registration/ehco-new-headteacher", submit_form: true) do
      page.choose "Yes", visible: :all
    end

    expect_page_to_have(path: "/registration/your-employment", submit_form: true) do
      expect(page).to have_text("How are you employed?")
      page.choose("In an independent hospital education organisation", visible: :all)
    end

    expect_page_to_have(path: "/registration/your-employer", submit_form: true) do
      page.fill_in "What organisation are you employed by?", with: "Big company"
    end

    expect_page_to_have(path: "/registration/ehco-possible-funding", submit_form: false) do
      expect(page).to have_content "You’re eligible for DfE scholarship funding for the Early headship coaching offer"
      page.click_link("Continue to register")
    end

    choose_provider_share_information_and_check_answers(provider: "Teach First") do
      expect(page).to have_content 'funding_eligiblity_status_code: "funded"'
    end

    check_back_journey_is_correct(exclude_current_page: true)
  end

  scenario "when the work setting is 'Another setting' - lead mentor" do
    complete_journey_as_far_as_choosing_a_work_setting(
      course: "Early headship coaching offer",
      work_setting: "Another setting",
    )

    expect_page_to_have(path: "/registration/npqh-status", submit_form: true) do
      page.choose "I’m doing it", visible: :all
    end

    expect_page_to_have(path: "/registration/ehco-new-headteacher", submit_form: true) do
      page.choose "Yes", visible: :all
    end

    expect_page_to_have(path: "/registration/your-employment", submit_form: true) do
      expect(page).to have_text("How are you employed?")
      page.choose("As a lead mentor for an accredited initial teacher training (ITT) provider", visible: :all)
    end

    choose_an_itt_provider(js: false, name: IttProvider.currently_approved.first.legal_name)

    expect_page_to_have(path: "/registration/ehco-possible-funding", submit_form: false) do
      expect(page).to have_content "You’re eligible for DfE scholarship funding for the Early headship coaching offer"
      page.click_link("Continue to register")
    end

    choose_provider_share_information_and_check_answers(provider: "Teach First") do
      expect(page).to have_content 'funding_eligiblity_status_code: "funded"'
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
      page.choose("Early headship coaching offer", visible: :all)
    end

    expect_page_to_have(path: "/registration/work-setting", submit_form: true) do
      page.choose("Another setting", visible: :all)
    end

    expect_page_to_have(path: "/registration/npqh-status", submit_form: true) do
      page.choose "I’m doing it", visible: :all
    end

    expect_page_to_have(path: "/registration/ehco-new-headteacher", submit_form: true) do
      page.choose "Yes", visible: :all
    end

    expect_page_to_have(path: "/registration/your-employment", submit_form: true) do
      expect(page).to have_text("How are you employed?")
      page.choose("In an independent hospital education organisation", visible: :all)
    end

    expect_page_to_have(path: "/registration/your-employer", submit_form: true) do
      page.fill_in "What organisation are you employed by?", with: "Big company"
    end

    choose_provider_share_information_and_check_answers(provider: "Teach First") do
      expect(page).to have_content 'funding_eligiblity_status_code: "requested_no_funding"'
    end

    check_back_journey_is_correct(exclude_current_page: true)
  end

  scenario "when the work setting is 'Other'" do
    complete_journey_as_far_as_choosing_a_work_setting(
      course: "Early headship coaching offer",
      work_setting: "Other",
    )

    expect_page_to_have(path: "/registration/npqh-status", submit_form: true) do
      page.choose "I’m doing it", visible: :all
    end

    expect_page_to_have(path: "/registration/ehco-new-headteacher", submit_form: true) do
      page.choose "Yes", visible: :all
    end

    expect_page_to_have(path: "/registration/referred-by-return-to-teaching-adviser", submit_form: true) do
      page.choose("Yes", visible: :all)
    end

    expect_page_to_have(path: "/registration/ehco-possible-funding", submit_form: false) do
      expect(page).to have_content "You’re eligible for DfE scholarship funding for the Early headship coaching offer because you are a headteacher in your first 5 years of headship."
      page.click_link("Continue to register")
    end

    choose_provider_share_information_and_check_answers(provider: "Teach First") do
      expect(page).to have_content 'funding_eligiblity_status_code: "funded"'
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
      page.choose("Early headship coaching offer", visible: :all)
    end

    expect_page_to_have(path: "/registration/work-setting", submit_form: true) do
      page.choose("Other", visible: :all)
    end

    expect_page_to_have(path: "/registration/npqh-status", submit_form: true) do
      page.choose "I’m doing it", visible: :all
    end

    expect_page_to_have(path: "/registration/ehco-new-headteacher", submit_form: true) do
      page.choose "Yes", visible: :all
    end

    choose_provider_share_information_and_check_answers(provider: "Teach First") do
      expect(page).to have_content 'funding_eligiblity_status_code: "requested_no_funding"'
    end

    check_back_journey_is_correct(exclude_current_page: true)
  end
end
