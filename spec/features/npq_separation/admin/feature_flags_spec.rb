require "rails_helper"

RSpec.feature "Administering feature flags", :rack_test_driver, type: :feature do
  include Helpers::AdminLogin
  include_context "Stub Get An Identity Omniauth Responses"

  let(:super_admin) { create(:super_admin) }

  scenario "super admins can see the list of feature flags and change their state" do
    create(:cohort, :current)
    sign_in_as_super_admin
    visit "/npq-separation/admin"
    page.click_link("Feature flags")
    expect(page).to have_current_path("/npq-separation/admin/features")

    within("tr", text: "Registration open") do
      page.click_link("View")
    end
    expect(page).to have_link("Closed registration enabled", href: "/npq-separation/admin/features/Closed%20registration%20enabled")

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

  scenario "check all feature flag pages are not missing translations" do
    sign_in_as_super_admin

    Feature::FEATURE_FLAG_KEYS.each do |feature_flag|
      visit npq_separation_admin_features_path
      within("tr", text: feature_flag) do
        page.click_link("View")
      end
    end
  end
end
