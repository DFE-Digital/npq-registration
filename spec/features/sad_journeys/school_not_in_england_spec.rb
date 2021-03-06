require "rails_helper"

RSpec.feature "Happy journeys", type: :feature do
  include Helpers::JourneyHelper
  include Helpers::JourneyAssertionHelper

  include_context "retrieve latest application data"
  include_context "stub course ecf to identifier mappings"

  scenario "school not in england" do
    stub_participant_validation_request

    navigate_to_page(path: "/", submit_form: false, axe_check: false) do
      expect(page).to have_text("Before you start")
      page.click_link("Start now")
    end

    expect_page_to_have(path: "/registration/provider-check", submit_form: true) do
      expect(page).to have_text("Have you already chosen an NPQ and provider?")
      page.choose("Yes", visible: :all)
    end

    # expect(page).to be_axe_clean
    # TODO: aria-expanded
    expect_page_to_have(path: "/registration/teacher-catchment", axe_check: false, submit_form: true) do
      page.choose("England", visible: :all)
    end

    expect_page_to_have(path: "/registration/work-in-school", submit_form: true) do
      page.choose("Yes", visible: :all)
    end

    expect_page_to_have(path: "/registration/teacher-reference-number", submit_form: true) do
      page.choose("Yes", visible: :all)
    end

    expect_page_to_have(path: "/registration/contact-details", submit_form: true) do
      expect(page).to have_text("What's your email address?")
      page.fill_in "What's your email address?", with: "user@example.com"
    end

    expect_page_to_have(path: "/registration/confirm-email", submit_form: true) do
      expect(page).to have_text("Confirm your code")
      expect(page).to have_text("user@example.com")

      code = ActionMailer::Base.deliveries.last[:personalisation].unparsed_value[:code]

      page.fill_in("Enter your code", with: code)
    end

    expect_page_to_have(path: "/registration/qualified-teacher-check", submit_form: true) do
      expect(page).to have_text("Check your details")

      page.fill_in "Teacher reference number (TRN)", with: "1234567"
      page.fill_in "Full name", with: "John Doe"
      page.fill_in "Day", with: "13"
      page.fill_in "Month", with: "12"
      page.fill_in "Year", with: "1980"
      page.fill_in "National Insurance number", with: "AB123456C"
    end

    School.create!(urn: 100_000, name: "open welsh school", county: "Wrexham", establishment_status_code: "1", establishment_type_code: "30")

    expect_page_to_have(path: "/registration/find-school", submit_form: true) do
      expect(page).to have_text("Where is your school, college or academy trust?")
      page.fill_in "Workplace location", with: "wrexham"
    end

    expect_page_to_have(path: "/registration/choose-school", submit_form: true) do
      expect(page).to have_text("Choose your workplace")

      within ".npq-js-reveal" do
        page.fill_in "Enter the name of your workplace", with: "open"
      end

      expect(page).to have_content("open welsh school")

      page.find("#school-picker__option--0").click
    end

    expect_page_to_have(path: "/registration/school-not-in-england", submit_form: false) do
      expect(page).to have_text("School or college must be in England")

      page.click_link("Back")
    end

    expect_page_to_have(path: "/registration/choose-school", submit_form: false) do
      expect(page).to have_text("Choose your workplace")
    end

    expect(retrieve_latest_application_user_data).to eq(nil)
    expect(retrieve_latest_application_data).to eq(nil)
  end
end
