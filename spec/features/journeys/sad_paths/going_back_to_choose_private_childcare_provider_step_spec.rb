require "rails_helper"

RSpec.feature "Sad journeys", :with_cohorts, :with_default_nursery, :with_default_schedules, type: :feature do
  include Helpers::JourneyAssertionHelper
  include Helpers::JourneyStepHelper
  include ApplicationHelper

  include_context "with stubbed Teacher Auth OmniAuth responses"
  include_context "with stubbed Teaching Record System person API"

  let(:nursery_name) { "open" }

  context "with JS", :js do
    scenario("going back to the choose private childcare provider step") { run_scenario(js: true) }
  end

  context "without JS", :no_js do
    scenario("going back to the choose private childcare provider step") { run_scenario(js: false) }
  end

  def run_scenario(js:)
    # first, get past the choose private childcare provider step

    complete_journey_as_far_as_choosing_a_work_setting(
      course: "Early years leadership",
      work_setting: "Early years or childcare",
    )

    navigate_to_page(path: "/registration/kind-of-nursery", submit_form: true) do
      page.choose("Private nursery", visible: :all)
    end

    expect_page_to_have(path: "/registration/have-ofsted-urn", submit_form: true) do
      expect(page).to have_text("Do you or your employer have an Ofsted unique reference number (URN)?")
      page.choose("Yes", visible: :all)
    end

    choose_a_private_childcare_provider(js:, urn: default_nursery.provider_urn, name: default_nursery.name)

    expect_page_to_have(path: "/registration/possible-funding", submit_form: false)

    # go back to the choose private childcare provider step

    click_link "Back"
    expect(page).to have_checked_field("Early years or childcare", visible: :all)
    click_button "Continue"
    expect(page).to have_checked_field("Private nursery", visible: :all)
    click_button "Continue"
    expect(page).to have_checked_field("Yes", visible: :all)
    click_button "Continue"
    expect_private_childcare_provider_picker_to_have_selected(js:, nursery: default_nursery)

    # go to the check your answers page and then back to the choose private childcare provider step

    click_button "Continue"

    navigate_to_page(path: "/registration/possible-funding", submit_form: false) do
      page.click_button("Continue to register")
    end

    navigate_to_page(path: "/registration/choose-your-provider", submit_form: true) do
      page.choose("Teach First", visible: :all)
    end

    navigate_to_page(path: "/registration/share-provider", submit_form: true) do
      page.check("Yes, I agree to share my information", visible: :all)
    end

    expect_page_to_have(path: "/registration/check-answers", submit_form: true) do
      page.click_link("Change", href: "/registration/have-ofsted-urn/change")
      page.choose("Yes", visible: :all)
    end

    expect_private_childcare_provider_picker_to_have_selected(js:, nursery: default_nursery)
  end
end
