require "rails_helper"

RSpec.feature "Short circuiting pages", :no_js, type: :feature do
  include_context "with stubbed Teacher Auth OmniAuth responses"

  scenario "visit /registration/check-answers directly" do
    visit "/registration/check-answers"
    expect(page).to have_current_path("/")
  end
end
