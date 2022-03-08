require "rails_helper"

RSpec.feature "Service is hard closed", type: :feature do
  before do
    allow(Services::Feature).to receive(:registration_closed?).and_return(true)
  end

  scenario "Service close date has passed" do
    visit "/"
    expect(page).to have_content("Registration for NPQs has closed temporarily")
    expect(page).to be_axe_clean

    page.click_link("Sign up for an email")
    expect(page).to have_content("What’s your email address?")
    expect(page).to be_axe_clean
  end
end
