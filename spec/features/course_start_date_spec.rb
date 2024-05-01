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
    let(:course_start_date) { Date.tomorrow }

    before do
      Setting.create(course_start_date:)
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
        expect(page).to have_text("Do you want to start a course before #{course_start_date.strftime("%B %Y")}?")
      end
    end
  end
end
