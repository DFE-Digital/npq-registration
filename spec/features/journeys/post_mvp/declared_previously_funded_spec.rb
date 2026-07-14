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

  scenario "Declared as previously funded" do
    choose_course_start_date(first_option: false)

    expect_page_to_have(path: "/registration/choose-your-npq", submit_form: true) do
      expect(page).to have_text("Choose an NPQ")
      page.choose("Headship", visible: :all)
    end

    expect_page_to_have(path: "/registration/funding-history", submit_form: true) do
      expect(page).to have_text("Have you received DfE funding for this course before?")
      page.choose("Yes", visible: :all)
    end

    expect_page_to_have(path: "/registration/ineligible-for-funding-previously-funded", submit_form: false) do
      expect(page).to have_text("You’re not eligible for DfE scholarship funding because you have received DfE funding for this course before.")
    end

    # check back links
    click_link("Back")
    expect(page).to have_current_path("/registration/funding-history")
    click_link("Back")
    expect(page).to have_current_path("/registration/choose-your-npq")
    # subsequent back links tested in check_if_youre_eligible_spec.rb
  end

  scenario "Declared as not previously funded" do
    choose_course_start_date(first_option: false)

    expect_page_to_have(path: "/registration/choose-your-npq", submit_form: true) do
      expect(page).to have_text("Choose an NPQ")
      page.choose("Headship", visible: :all)
    end

    expect_page_to_have(path: "/registration/funding-history", submit_form: true) do
      expect(page).to have_text("Have you received DfE funding for this course before?")
      page.choose("No", visible: :all)
    end

    expect_page_to_have(path: "/registration/work-setting", submit_form: false)

    # check back links
    click_link("Back")
    expect(page).to have_current_path("/registration/funding-history")
    click_link("Back")
    expect(page).to have_current_path("/registration/choose-your-npq")
  end
end
