require "rails_helper"

RSpec.feature "Account", type: :feature do
  include_context "Stub Get An Identity Omniauth Responses"

  scenario "when not logged in, it redirects to sign in" do
    visit "/account"
    expect(page).to be_accessible
    expect(page).to have_current_path("/sign-in")
  end
end
