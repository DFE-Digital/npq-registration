require "rails_helper"

RSpec.feature "super admin", :rack_test_driver, type: :feature do
  include Helpers::AdminLogin
  include_context "Stub Get An Identity Omniauth Responses"

  let(:super_admin) { create(:super_admin) }

  # This currently reflects only the feature flags link which has been just added to the separation admin console. More links will be added as more sections are moved from the legacy admin console to the new admin console.
  scenario "super admins can see links that regular admins can't" do
    create(:cohort, :current)
    sign_in_as_super_admin
    visit "/npq-separation/admin"
    click_link("Separation Admin")
    expect(page).to have_link("Feature flags", href: "/npq-separation/admin/features")
  end

  scenario "super admins can see the list of feature flags and change their state" do
    create(:cohort, :current)
    sign_in_as_super_admin
    visit "/npq-separation/admin"
    page.click_link("Feature flags")
    expect(page).to have_current_path("/npq-separation/admin/features")
    within("tr", text: "Registration open") do
      page.click_link("View")
    end
    expect(page).to have_current_path("/npq-separation/admin/features/Registration open")
    expect(page).to have_content("Registration open")
    expect(Flipper.enabled?(Feature::REGISTRATION_OPEN)).to be(true)
    fill_in "Confirm the feature flag name to change the state", with: "wrong answer"
    page.click_button "Change state"
    expect(page).to have_content("There was an error updating the feature flag.")
    fill_in "Confirm the feature flag name to change the state", with: "Registration open"
    page.click_button "Change state"
    expect(page).to have_content("You have turned the Registration open feature flag off.")
    expect(Flipper.enabled?(Feature::REGISTRATION_OPEN)).to be(false)
  end
end

