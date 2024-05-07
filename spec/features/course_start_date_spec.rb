require "rails_helper"

RSpec.feature "Happy journeys", type: :feature do
  include Helpers::JourneyAssertionHelper
  include Helpers::JourneyStepHelper
  include ApplicationHelper

  include_context "Stub Get An Identity Omniauth Responses"

  context "when course start date not is set" do
    scenario do
      stub_participant_validation_request

      navigate_to_page(path: "/", submit_form: false, axe_check: false) do
        expect(page).to have_text("Before you start")
        page.click_button("Start now")
      end

      expect(page).not_to have_content("Before you start")

      expect_page_to_have(path: "/registration/course-start-date", submit_form: true) do
        expect(page).to have_text("NPQ start dates are usually every February and October.")
        expect(page).to have_text("Do you want to start a course before (please contact support for newest date)?")
      end
    end
  end

  context "when course start date is set" do
    before do
      Setting.create!(course_start_date: Date.new(2024, 5, 1))
      travel_to(Date.new(2024, 4, 1))
    end

    scenario do
      stub_participant_validation_request

      navigate_to_page(path: "/", submit_form: false, axe_check: false) do
        expect(page).to have_text("Before you start")
        page.click_button("Start now")
      end

      expect(page).not_to have_content("Before you start")

      expect_page_to_have(path: "/registration/course-start-date", submit_form: true) do
        expect(page).to have_text("NPQ start dates are usually every February and October.")
        expect(page).to have_text("Do you want to start a course before May 2024?")
      end
    end
  end
end
