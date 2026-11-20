require "rails_helper"

RSpec.feature "Happy journeys", :no_js, :with_cohorts, :with_default_schedules, type: :feature do
  include Helpers::JourneyAssertionHelper
  include Helpers::JourneyStepHelper

  let(:school) { create(:school, :eligible_with_urn_and_address) }

  before { school }

  scenario "changing work setting from other to school" do
    complete_journey_as_far_as_choosing_a_work_setting(
      course: "Senior leadership",
      work_setting: "Other",
    )

    expect_page_to_have(path: "/registration/referred-by-return-to-teaching-adviser", submit_form: true) do
      page.choose("Yes", visible: :all)
    end

    expect_page_to_have(path: "/registration/possible-funding", submit_form: true) do
      expect(page).to have_content "In review"
    end

    choose_provider_share_information_and_check_answers(provider: "Teach First") do
      expect(page).to have_content 'funding_eligiblity_status_code: "referred_by_return_to_teaching_adviser"'
    end

    # now go back and change work setting to a school

    click_link("Change", href: "/registration/work-setting/change")

    expect_page_to_have(path: "/registration/work-setting/change", submit_form: true) do
      page.choose("A school", visible: :all)
      page.choose("Primary school (5 to 11)", visible: :all)
    end

    choose_a_school(js: false, name: "open", path: "/registration/choose-school/change")

    expect_page_to_have(path: "/registration/possible-funding/change", submit_form: true) do
      expect(page).not_to have_content "In review"
      expect(page).to have_text("DfE scholarship funding")
      expect(page).to have_text("You’re eligible for scholarship funding for the Senior leadership NPQ")
    end
  end
end
