require "rails_helper"

RSpec.feature "admin area", type: :feature do
  let(:admin) { create(:admin) }

  context "when I'm signed in as an admin" do
    include_context "sign in as admin"

    scenario "I can see the admin area when navigating to /admin" do
      visit("/admin")
      expect(page.current_path).to eql("/admin")

      expect(page).to have_link("Applications")
      expect(page).to have_link("Manual validation")
    end
  end

  context "when I'm not signed in as an admin" do
    scenario "I'm redirected to /sign-in when I navigate to /admin" do
      visit("/admin")
      expect(page.current_path).to eql("/sign-in")
    end
  end
end
