require "rails_helper"

RSpec.feature "visiting steps that do not exist", type: :feature do
  include_context "Stub Get An Identity Omniauth Responses"

  context "when not logged in" do
    scenario "visiting steps that used to exist", :no_js do
      visit "/registration/confirmation"
      expect(page).to have_current_path "/"

      visit "/registration/about-npq"
      expect(page).to have_current_path "/"

      visit "/registration/choosen-start-date"
      expect(page).to have_current_path "/"
    end
  end

  context "when logged in" do
    before do
      visit "/"
      page.click_button("Start now")
    end

    scenario "visiting steps that used to exist", :no_js do
      visit "/registration/confirmation"
      expect(page).to have_current_path "/registration/course-start-date"

      visit "/registration/about-npq"
      expect(page).to have_current_path "/registration/course-start-date"

      visit "/registration/choosen-start-date"
      expect(page).to have_current_path "/registration/course-start-date"

      visit "/registration/find-school"
      expect(page).to have_current_path "/registration/course-start-date"

      visit "/registration/find-childcare-provider"
      expect(page).to have_current_path "/registration/course-start-date"
    end
  end

  scenario "visiting steps that never existed", :no_js do
    expect { visit("/registration/this-step-never-existed") }.to raise_error(RegistrationWizard::InvalidStep)
  end
end
