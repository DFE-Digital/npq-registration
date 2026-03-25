require "rails_helper"

RSpec.feature "Sad journeys", :with_default_schedules, type: :feature do
  include Helpers::JourneyAssertionHelper
  include Helpers::JourneyStepHelper
  include ApplicationHelper

  include_context "Stub Get An Identity Omniauth Responses"

  let(:user_trn) { "" }
  let(:manually_entered_trn) { "3651763" }

  scenario "session expires before qualified teacher check - no DQT mismatch", :no_js do
    stub_participant_validation_request(trn: manually_entered_trn, response: { trn: manually_entered_trn, date_of_birth: "1980-12-13" })

    navigate_to_page(path: "/", submit_form: false, axe_check: false) do
      expect(page).to have_text("Before you start")
      page.click_button("Start now")
    end

    expect(page).not_to have_content("Before you start")

    expect_page_to_have(path: "/registration/teacher-reference-number", submit_form: true) do
      page.choose("No, I need to request one", visible: :all)
    end

    expect_page_to_have(path: "/registration/dont-have-teacher-reference-number", submit_form: false) do
      expect(page).to have_text("Get a teacher reference number (TRN) before registering for an NPQ")

      page.click_link("Back")
    end

    expect_page_to_have(path: "/registration/teacher-reference-number", submit_form: true) do
      page.choose("Yes", visible: :all)
    end

    expect_page_to_have(path: "/registration/qualified-teacher-check", submit_form: true) do
      travel_to 3.weeks.from_now # expire the session by going to when the session would have expired
      page.fill_in "Teacher reference number (TRN)", with: manually_entered_trn
      page.fill_in "Full name", with: "Jane Smith"
      page.fill_in "Day", with: "13"
      page.fill_in "Month", with: "12"
      page.fill_in "Year", with: "1980"
      page.fill_in "National Insurance number", with: "AB123456C"
    end

    expect(page).to have_current_path("/")
  end

  scenario "session expires before qualified teacher check - DQT mismatch", :no_js do
    stub_inactive_participant_validation_request(trn: manually_entered_trn)

    navigate_to_page(path: "/", submit_form: false, axe_check: false) do
      expect(page).to have_text("Before you start")
      page.click_button("Start now")
    end

    expect(page).not_to have_content("Before you start")

    expect_page_to_have(path: "/registration/teacher-reference-number", submit_form: true) do
      page.choose("No, I need to request one", visible: :all)
    end

    expect_page_to_have(path: "/registration/dont-have-teacher-reference-number", submit_form: false) do
      expect(page).to have_text("Get a teacher reference number (TRN) before registering for an NPQ")

      page.click_link("Back")
    end

    expect_page_to_have(path: "/registration/teacher-reference-number", submit_form: true) do
      page.choose("Yes", visible: :all)
    end

    expect_page_to_have(path: "/registration/qualified-teacher-check", submit_form: true) do
      travel_to 3.weeks.from_now # expire the session by going to when the session would have expired
      page.fill_in "Teacher reference number (TRN)", with: manually_entered_trn
      page.fill_in "Full name", with: "Jane Smith"
      page.fill_in "Day", with: "13"
      page.fill_in "Month", with: "12"
      page.fill_in "Year", with: "1980"
      page.fill_in "National Insurance number", with: "AB123456C"
    end

    expect(page).to have_current_path("/")
  end
end
