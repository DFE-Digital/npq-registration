require "rails_helper"

RSpec.feature "Happy journeys", :no_js, :with_cohorts, :with_default_schedules, :with_default_school, type: :feature do
  include Helpers::JourneyAssertionHelper
  include Helpers::JourneyStepHelper
  include ApplicationHelper

  scenario "When not logged in" do
    navigate_to_page(path: "/", submit_form: false) do
      page.click_button("Start now")
    end

    expect(page).to have_current_path("/registration/course-start-date")
  end
end
