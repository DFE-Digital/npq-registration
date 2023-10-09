require "rails_helper"

RSpec.feature "Happy journeys", type: :feature do
  include Helpers::JourneyAssertionHelper

  include_context "retrieve latest application data"
  include_context "Stub previously funding check for all courses" do
    let(:api_call_trn) { user_trn }
  end
  include_context "Stub Get An Identity Omniauth Responses"

  scenario "school not in england" do
    stub_participant_validation_request

    navigate_to_page(path: "/", submit_form: false, axe_check: false) do
      expect(page).to have_text("Before you start")
      page.click_button("Start now")
    end

    expect(page).not_to have_content("Before you start")

    expect_page_to_have(path: "/registration/provider-check", submit_form: true) do
      expect(page).to have_text("Have you chosen an NPQ and provider?")
      page.choose("Yes", visible: :all)
    end

    # expect(page).to be_axe_clean
    # TODO: aria-expanded
    expect_page_to_have(path: "/registration/teacher-catchment", axe_check: false, submit_form: true) do
      page.choose("Yes", visible: :all)
    end

    expect_page_to_have(path: "/registration/work-setting", submit_form: true) do
      page.choose("A school", visible: :all)
    end

    School.create!(urn: 100_000, name: "open welsh school", county: "Wrexham", establishment_status_code: "1", establishment_type_code: "30")

    expect_page_to_have(path: "/registration/find-school", submit_form: true) do
      page.fill_in "Where is your workplace located?", with: "wrexham"
    end

    expect_page_to_have(path: "/registration/choose-school", submit_form: true) do
      within ".npq-js-reveal" do
        page.fill_in "What’s the name of your workplace?", with: "open"
      end

      expect(page).to have_content("open welsh school")

      page.find("#school-picker__option--0").click
    end

    expect_page_to_have(path: "/registration/school-not-in-england", submit_form: false) do
      expect(page).to have_text("School or college must be in England")

      page.click_link("Back")
    end

    expect_page_to_have(path: "/registration/choose-school", submit_form: false) do
      expect(page).to have_text("What’s the name of your workplace?")
    end

    expect(retrieve_latest_application_user_data).to match(nil)
    expect(retrieve_latest_application_data).to match(nil)
  end
end
