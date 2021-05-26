require "rails_helper"

RSpec.feature "Sessions", type: :feature do
  scenario "signing in" do
    visit "/sign-in"
    expect(page).to have_content("Sign in")
  end
end
