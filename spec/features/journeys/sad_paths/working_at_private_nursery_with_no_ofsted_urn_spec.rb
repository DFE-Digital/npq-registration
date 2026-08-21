require "rails_helper"

RSpec.feature "Sad journeys", :no_js, :with_cohorts, :with_default_schedules, :with_eligibility_list_entries, type: :feature do
  include Helpers::JourneyAssertionHelper
  include Helpers::JourneyStepHelper
  include ApplicationHelper

  include_context "with stubbed Teacher Auth OmniAuth responses"
  include_context "with stubbed Teaching Record System person API"

  scenario "working at a private nursery with no OFSTED URN" do
    complete_journey_as_far_as_choosing_a_work_setting(
      course: "Early years leadership",
      work_setting: "Early years or childcare",
    )

    expect_page_to_have(path: "/registration/kind-of-nursery", submit_form: true) do
      expect(page).to have_text("Which early years setting do you work in?")
      page.choose("Private nursery", visible: :all)
    end

    expect_page_to_have(path: "/registration/have-ofsted-urn", submit_form: true) do
      expect(page).to have_text("Do you or your employer have an Ofsted unique reference number (URN)?")
      page.choose("No", visible: :all)
    end

    expect_page_to_have(path: "/registration/possible-funding", submit_form: true) do
      expect(page).to have_text("You’re eligible for scholarship funding for the Early years leadership NPQ")
    end
  end
end
