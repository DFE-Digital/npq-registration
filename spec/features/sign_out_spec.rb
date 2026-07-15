require "rails_helper"

RSpec.feature "Signing out", :no_js, type: :feature do
  include Helpers::AdminLogin

  let(:admin) { create(:admin) }

  scenario "signing out via the confirmation page" do
    sign_in_as(admin)

    click_link "Sign out"

    expect(page).to have_current_path("/sign-out")
    expect(page).to have_content("Are you sure you want to sign out?")
    expect(page).to be_accessible

    click_button "Sign out"

    expect(page).to have_current_path("/")
    visit "/admin"
    expect(page).to have_current_path(sign_in_path)
  end

  scenario "cancelling returns to the previous page" do
    sign_in_as(admin)

    click_link "Sign out"
    click_link "Stay signed in"

    expect(page).to have_current_path("/admin")
  end

  scenario "visiting the confirmation page when signed out redirects to the homepage" do
    visit "/sign-out"

    expect(page).to have_current_path("/")
  end

  context "with a Get an Identity user" do
    include_context "Stub Get An Identity Omniauth Responses"

    before do
      allow(User).to receive(:find_by).and_return(create(:user, :with_get_an_identity_id))
    end

    scenario "the header link shows the confirmation page" do
      visit "/"
      click_link "Sign out"

      expect(page).to have_current_path("/sign-out")
      expect(page).to have_content("Are you sure you want to sign out?")
      expect(page).to have_button("Sign out")
      expect(page).to have_link("Stay signed in")
    end
  end
end
