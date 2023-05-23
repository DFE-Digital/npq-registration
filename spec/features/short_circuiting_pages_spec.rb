require "rails_helper"

RSpec.feature "Short circuiting pages", type: :feature do
  include_context "Stub Get An Identity Omniauth Responses"

  scenario "visit /registration/check-answers directly" do
    visit "/registration/check-answers"
    expect(page).to have_current_path("/")
  end
end
