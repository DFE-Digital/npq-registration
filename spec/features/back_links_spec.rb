require "rails_helper"

RSpec.feature "Back links", type: :feature do
  include Helpers::JourneyHelper
  include Helpers::JourneyAssertionHelper

  include_context "Stub Get An Identity Omniauth Responses"

  scenario "back to previous page retains state" do
    visit "/"

    navigate_to_page(path: "/", submit_form: false, axe_check: false) do
      expect(page).to have_text("Before you start")
      page.click_button("Start now")
    end

    expect(page).not_to have_content("Before you start")

    expect_page_to_have(path: "/registration/provider-check", submit_form: true) do
      page.choose("Yes", visible: :all)
    end

    expect_page_to_have(path: "/registration/teacher-catchment", submit_form: false, axe_check: false)
    page.click_link("Back")

    expect_page_to_have(path: "/registration/provider-check", submit_form: false, axe_check: false)

    expect(page).to have_checked_field("Yes", visible: :all)
  end
end
