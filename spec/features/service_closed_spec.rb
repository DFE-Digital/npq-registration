require "rails_helper"

RSpec.feature "Service is hard closed", type: :feature do
  scenario "Service close date has passed" do
    close_registration!

    visit "/"
    expect(page).to have_content("Registration for NPQs has closed temporarily")
    expect(page).to be_axe_clean

    page.click_link("Sign up for an email")
    expect(page).to have_content("What’s your email address?")
    expect(page).to be_axe_clean
  end

  scenario "Services closes while registration in progress" do
    open_registration!

    visit "/"
    expect(page).to have_text("Before you start")
    page.click_link("Start now")

    expect(page).to have_text("Have you already chosen an NPQ and provider?")
    page.choose("Yes", visible: :all)

    # Registration is now closed
    close_registration!
    page.click_button("Continue")

    expect(page).to have_content("Registration for NPQs has closed temporarily")
  end

private

  def close_registration!
    allow(Services::Feature).to receive(:features_enabled?).and_return(true)
    allow(Services::Feature).to receive(:registration_closed?).and_return(true)
  end

  def open_registration!
    allow(Services::Feature).to receive(:features_enabled?).and_return(true)
    allow(Services::Feature).to receive(:registration_closed?).and_return(false)
  end
end
