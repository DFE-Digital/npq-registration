require "rails_helper"

RSpec.feature "Start page", type: :feature do
  include_context "Stub Get An Identity Omniauth Responses"

  scenario "Navigate to home" do
    visit "/"

    expect(page).to be_accessible
    expect(page).to have_text("Before you start")
  end
end
