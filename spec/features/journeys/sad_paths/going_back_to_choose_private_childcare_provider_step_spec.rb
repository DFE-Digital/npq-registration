require "rails_helper"

RSpec.feature "Sad journeys", :with_cohorts, :with_default_schedules, :with_default_school, type: :feature do
  include Helpers::JourneyAssertionHelper
  include Helpers::JourneyStepHelper
  include ApplicationHelper

  include_context "with stubbed Teacher Auth OmniAuth responses"
  include_context "with stubbed Teaching Record System person API"

  let(:school_name) { "open" }
  # let(:school) { create(:school, urn: 100_000, name: "some school", establishment_status_code: "1") }

  # before { school }

  context "when JavaScript is enabled", :js do
    scenario("going back to the choose private childcare provider step") { run_scenario(js: true) }
  end

  context "when JavaScript is disabled", :no_js do
    scenario("going back to the choose private childcare provider step") { run_scenario(js: false) }
  end

  def run_scenario(js:)
    # first, get past the choose private childcare provider step

    stub_participant_validation_request

    navigate_to_page(path: "/", submit_form: false, axe_check: false) do
      page.click_button("Start now")
    end

    choose_course_start_date

    navigate_to_page(path: "/registration/provider-check", submit_form: true) do
      page.choose("Yes", visible: :all)
    end

    navigate_to_page(path: "/registration/teacher-catchment", axe_check: false, submit_form: true) do
      page.choose("Yes", visible: :all)
    end

    navigate_to_page(path: "/registration/work-setting", submit_form: true) do
      page.choose("Early years or childcare", visible: :all)
    end

    navigate_to_page(path: "/registration/kind-of-nursery", submit_form: true) do
      page.choose("Private nursery", visible: :all)
    end

    expect_page_to_have(path: "/registration/have-ofsted-urn", submit_form: true) do
      expect(page).to have_text("Do you or your employer have an Ofsted unique reference number (URN)?")
      page.choose("Yes", visible: :all)
    end

    choose_a_private_childcare_provider(js:, urn: "EY487263", name: "searchable childcare provider")

    expect_page_to_have(path: "/registration/choose-your-npq", submit_form: false)

    # try to go back to the choose private childcare provider step and continue without changing anything

    click_link "Back"
    click_button "Continue"

    expect(page).to have_text("Enter a private childcare provider")

    # try going to the check your answers page and then back to the choose private childcare provider step

    choose_a_childcare_provider(js:, name: school_name)

    expect_page_to_have(path: "/registration/choose-your-npq", submit_form: true) do
      page.choose("Early years leadership", visible: :all)
    end

    navigate_to_page(path: "/registration/possible-funding", submit_form: false) do
      page.click_button("Continue")
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

    click_button "Continue"

    expect(page).to have_text("Enter a private childcare provider")
  end
end
