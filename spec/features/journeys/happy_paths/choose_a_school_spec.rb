require "rails_helper"

RSpec.feature "Choose a school page", :with_default_schedules, type: :feature do
  include Helpers::JourneyAssertionHelper
  include Helpers::JourneyStepHelper
  include ApplicationHelper

  include_context "Stub Get An Identity Omniauth Responses"

  before do
    stub_participant_validation_request

    School.create!(urn: 100_000, name: "an open school", establishment_status_code: "1")
    School.create!(urn: 100_001, name: "closed school", establishment_status_code: "2")
    School.create!(urn: 100_002, name: "another open school", establishment_status_code: "1")

    navigate_to_page(path: "/", submit_form: false, axe_check: false) do
      page.click_button("Start now")
    end

    navigate_to_page(path: "/registration/course-start-date", submit_form: true) do
      page.choose("Yes", visible: :all)
    end

    navigate_to_page(path: "/registration/provider-check", submit_form: true) do
      page.choose("Yes", visible: :all)
    end

    navigate_to_page(path: "/registration/teacher-catchment", axe_check: false, submit_form: true) do
      page.choose("Yes", visible: :all)
    end

    navigate_to_page(path: "/registration/work-setting", submit_form: true) do
      page.choose("A school", visible: :all)
    end
  end

  context "when JavaScript is enabled", :js do
    scenario "choosing a school" do
      expect_page_to_have(path: "/registration/choose-school", submit_form: true) do
        expect(page).to have_html(I18n.t("helpers.hint.registration_wizard.choose_school_html"), js: true)

        within ".npq-js-reveal" do
          page.fill_in "What is the name of your workplace?", with: "open"
        end

        expect(page).to have_content("an open school")
        expect(page).to have_content("another open school")

        page.find("#school-picker__option--0").click
        page.click_button("Continue")

        expect(page).to have_current_path("/registration/choose-your-npq")
      end
    end

    scenario "choosing a school with no results" do
      within ".npq-js-reveal" do
        page.fill_in "What is the name of your workplace?", with: "xxxx"
      end

      expect(page).to have_current_path("/registration/choose-school")
    end
  end

  context "when JavaScript is disabled", :no_js do
    scenario "choosing a school" do
      expect_page_to_have(path: "/registration/choose-school", submit_form: true) do
        expect(page).to have_html(I18n.t("helpers.hint.registration_wizard.choose_school_html"), js: false)

        within ".npq-js-hidden" do
          page.fill_in "What is the name of your workplace?", with: "open"
        end

        page.click_button("Continue")

        expect(page).to have_text(I18n.t("helpers.label.registration_wizard.choose_school_fallback"))
        expect(page).to have_content("an open school")
        expect(page).to have_content("another open school")

        page.choose "an open school"
        page.click_button("Continue")

        expect(page).to have_current_path("/registration/choose-your-npq")
      end
    end

    scenario "choosing a school with no results" do
      within ".npq-js-hidden" do
        page.fill_in "What is the name of your workplace?", with: "xxxx"
      end

      page.click_button("Continue")

      expect(page).to have_current_path("/registration/choose-school")
    end

    scenario "using 'Workplace not shown above' radio button" do
      within ".npq-js-hidden" do
        page.fill_in "What is the name of your workplace?", with: "open"
      end
      page.click_button("Continue")
      page.choose "Workplace not shown above"
      page.fill_in "registration-wizard-institution-name-field", with: "xxxx"
      page.click_button("Continue")

      expect(page).to have_content("No schools with the name xxxx were found, please try again")
      expect(page).to have_current_path("/registration/choose-school")
    end
  end
end
