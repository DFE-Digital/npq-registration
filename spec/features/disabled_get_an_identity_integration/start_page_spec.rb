require "rails_helper"

RSpec.feature "Start page", type: :feature do
  include_context "Disable Get An Identity integration"

  scenario "Navigate to home" do
    visit "/"

    expect(page).to be_axe_clean
    expect(page).to have_text("Before you start")
  end
end
