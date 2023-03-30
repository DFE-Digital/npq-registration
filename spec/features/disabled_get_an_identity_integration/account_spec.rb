require "rails_helper"

RSpec.feature "Account", type: :feature do
  include_context "Disable Get An Identity integration"

  scenario "when not logged in, it redirects to sign in" do
    visit "/account"
    expect(page).to be_axe_clean
    expect(page).to have_current_path("/sign-in")
  end
end
