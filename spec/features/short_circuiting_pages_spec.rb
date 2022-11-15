require "rails_helper"

RSpec.feature "Short circuiting pages", type: :feature do
  include_context "Enable Get An Identity integration"

  scenario "visit /registration/check-answers directly" do
    visit "/registration/check-answers"
    expect(page.current_path).to eql("/")
  end
end
