require "rails_helper"

RSpec.feature "Sad journeys", :no_js, :with_cohorts, :with_default_schedules, :with_default_school, :with_eligibility_list_entries, type: :feature do
  include Helpers::JourneyAssertionHelper
  include Helpers::JourneyStepHelper
  include ApplicationHelper

  scenario "registration journey when choosing Leading primary mathematics journey but cannot show understanding of mastery approaches to teaching maths" do
    complete_journey_as_far_as_choosing_a_work_setting(
      course: "Leading primary mathematics",
      work_setting: "Primary school (5 to 11)",
    )

    choose_a_school(js: false, name: "open")

    expect_page_to_have(path: "/registration/maths-eligibility-teaching-for-mastery", submit_form: true) do
      expect(page).to have_text("Have you taken at least one year of the primary maths Teaching for Mastery programme?")
      page.choose("No", visible: :all)
    end

    expect_page_to_have(path: "/registration/maths-understanding-of-approach", submit_form: true) do
      expect(page).to have_text("How can you show your understanding of mastery approaches to teaching maths?")
      page.choose("I cannot show an understanding of mastery approaches to teaching maths", visible: :all)
    end

    expect_page_to_have(path: "/registration/maths-cannot-register", submit_form: false) do
      expect(page).to have_text("You cannot register for the leading primary mathematics NPQ")
      expect(page).not_to have_button("Continue")
      expect(page).not_to have_link("Continue to register")
    end
  end
end
