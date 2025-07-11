require "rails_helper"

RSpec.feature "visiting steps that no not exist", type: :feature do
  include_context "Stub Get An Identity Omniauth Responses"

  scenario "visiting steps that used to exist", :no_js do
    visit "/registration/confirmation"
    expect(page).to have_current_path "/registration/course-start-date"

    visit "/registration/about_npq"
    expect(page).to have_current_path "/registration/course-start-date"

    visit "/registration/choosen_start_date"
    expect(page).to have_current_path "/registration/course-start-date"
  end

  scenario "visiting steps that never existed", :no_js do
    expect { visit("/registration/this-step-never-existed") }.to raise_error(RegistrationWizard::InvalidStep)
  end
end
