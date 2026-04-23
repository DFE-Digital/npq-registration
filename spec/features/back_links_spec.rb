require "rails_helper"

RSpec.feature "Back links", :with_default_schedules, type: :feature do
  include Helpers::JourneyAssertionHelper
  include Helpers::JourneyStepHelper

  include_context "Stub Get An Identity Omniauth Responses"

  scenario "back to previous page retains state" do
    visit "/"

    navigate_to_page(path: "/", submit_form: false, axe_check: false) do
      expect(page).to have_text("Before you start")
      page.click_button("Start now")
    end

    expect(page).not_to have_content("Before you start")

    choose_course_start_date

    expect_page_to_have(path: "/registration/provider-check", submit_form: false, axe_check: false)
    page.click_link("Back")

    expect_page_to_have(path: "/registration/course-start-date", submit_form: false, axe_check: false)

    expect(page).to have_checked_field(course_start_cohort_description, visible: :all)
  end
end
