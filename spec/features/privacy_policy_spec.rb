require "rails_helper"

RSpec.feature "Privacy Policy", type: :feature do
  include_context "Enable Get An Identity integration"

  scenario "view info about privacy policy" do
    visit "/"
    click_link("Privacy")

    expect(page).to be_axe_clean

    aggregate_failures do
      expect(page).to have_content("Privacy policy")
      expect(page).to have_content("This policy refers to data collected as part of the national professional qualifications programme")
    end
  end
end
