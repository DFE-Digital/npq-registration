require "rails_helper"

RSpec.feature "Account", type: :feature do
  include_context "Stub Get An Identity Omniauth Responses"

  describe "accounts page" do
    scenario "when not logged in, it redirects to sign in" do
      visit "/account"
      expect(page).to be_accessible
      expect(page).to have_current_path("/sign-in")
    end
  end

  describe "accounts user registration page" do
    let!(:application) { FactoryBot.create(:application) }

    scenario "when not logged in, it redirects to sign in" do
      visit(accounts_user_registration_path(application.id))

      expect(page).to have_current_path("/sign-in")
    end
  end
end
