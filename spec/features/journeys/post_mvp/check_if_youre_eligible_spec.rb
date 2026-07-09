require "rails_helper"

RSpec.feature "Happy journeys", :no_js, :with_cohorts, type: :feature do
  include Helpers::JourneyAssertionHelper
  include Helpers::JourneyStepHelper
  include ApplicationHelper

  include_context "with stubbed Teacher Auth OmniAuth responses"
  include_context "with stubbed Teaching Record System person API"

  before do
    navigate_to_page(path: "/", submit_form: false) do
      page.click_button("Start now")
    end
  end

  scenario "Autumn 2026 cohort with funding check - works in England" do
    choose_course_start_date

    expect_page_to_have(path: "/registration/check-funding", submit_form: true) do
      expect(page).to have_text("Check if you’re eligible for DfE scholarship funding")
      click_button("Check funding")
    end

    expect_page_to_have(path: "/registration/teacher-catchment", submit_form: true) do
      expect(page).to have_text("Do you work in England?")
      # choose("Yes", visible: :all) # TOOD: will be part of NPQ-3841
    end

    # check back links
    click_link("Back")
    expect(page).to have_current_path("/registration/check-funding")
    click_link("Back")
    expect(page).to have_current_path("/registration/course-start-date")
  end

  scenario "Autumn 2026 cohort with funding check - does not work in England" do
    choose_course_start_date

    expect_page_to_have(path: "/registration/check-funding", submit_form: true) do
      click_button("Check funding")
    end

    expect_page_to_have(path: "/registration/teacher-catchment", submit_form: true) do
      # choose("No", visible: :all) # TOOD: will be part of NPQ-3841
    end

    # check back links
    click_link("Back")
    expect(page).to have_current_path("/registration/check-funding")
    click_link("Back")
    expect(page).to have_current_path("/registration/course-start-date")
  end

  scenario "Autumn 2026 cohort without funding check" do
    choose_course_start_date

    expect_page_to_have(path: "/registration/check-funding", submit_form: true) do
      click_button("Continue without DfE funding")
    end

    expect_page_to_have(path: "/registration/choose-your-npq", submit_form: false) do
      expect(page).to have_text("Choose an NPQ")
    end

    # check back links
    click_link("Back")
    expect(page).to have_current_path("/registration/check-funding")
    click_link("Back")
    expect(page).to have_current_path("/registration/course-start-date")
  end

  scenario "Spring 2026 cohort" do
    choose_course_start_date(first_option: false)

    expect_page_to_have(path: "/registration/choose-your-npq", submit_form: false) do
      expect(page).to have_text("Choose an NPQ")
    end

    # check back links
    click_link("Back")
    expect(page).to have_current_path("/registration/course-start-date")
  end
end
