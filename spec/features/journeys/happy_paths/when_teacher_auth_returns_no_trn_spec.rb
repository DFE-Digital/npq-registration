require "rails_helper"

RSpec.feature "Sad journeys", :no_js, :with_cohorts, :with_default_schedules, :with_default_school, type: :feature do
  include Helpers::JourneyAssertionHelper
  include Helpers::JourneyStepHelper
  include ApplicationHelper

  include_context "with stubbed Teacher Auth OmniAuth responses"
  include_context "with stubbed missing Teaching Record System person record"

  context "when Teacher Auth returns no TRN" do
    let(:user_trn) { nil }

    scenario "the registration journey starts" do
      complete_journey_as_far_as_choosing_a_work_setting(
        course: "Headship",
        work_setting: "A school",
      )

      choose_a_school(js: false, name: "open")

      expect_page_to_have(path: "/registration/ineligible-for-funding", submit_form: false) do
        page.click_link("Continue")
      end

      expect_page_to_have(path: "/registration/funding-your-npq", submit_form: true) do
        page.choose "My trust is paying", visible: :all
      end

      expect_page_to_have(path: "/registration/choose-your-provider", submit_form: true) do
        page.choose("Teach First", visible: :all)
      end

      expect_page_to_have(path: "/registration/share-provider", submit_form: true) do
        page.check("Yes, I agree to share my information", visible: :all)
      end

      expect_page_to_have(path: "/registration/check-answers", submit_button_text: "Submit", submit_form: true) do
        expect_check_answers_page_to_have_answers(
          {
            "Course start" => course_start_cohort_description,
            "Course" => "Headship",
            "Provider" => "Teach First",
            "Workplace" => "open manchester school – street 1, manchester",
            "Course funding" => "My trust is paying",
            "Work setting" => "A school",
            "Workplace in England" => "Yes",
          },
        )
      end

      expect_applicant_reached_end_of_journey

      expect(retrieve_latest_application_user_data).to include(
        user_attributes_from_stubbed_callback_response.merge(
          "trn_verified" => false,
          "trn_auto_verified" => false,
        ),
      )
    end
  end
end
