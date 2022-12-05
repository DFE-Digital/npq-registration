require "rails_helper"

RSpec.feature "Privacy Policy", type: :feature do
  include_context "Disable Get An Identity integration"

  scenario "view info about privacy policy" do
    visit "/"
    click_link("Privacy")

    expect(page).to be_axe_clean

    aggregate_failures do
      expect(page).to have_css("h1", text: "Privacy policy")
      expect(page).to have_content("When you register for a national professional qualification (NPQ), the Department for Education (DfE) collects and processes some of your personal data.")
    end
  end
end
