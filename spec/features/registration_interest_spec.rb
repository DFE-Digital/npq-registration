require "rails_helper"

RSpec.feature "Register interest", type: :feature do
  scenario "Sign up to notification via NPQ registration path" do
    visit "/"

    expect(page).to have_text("Before you start")
    page.click_link("Start now")

    expect(page).to be_axe_clean
    expect(page).to have_text("Have you agreed a start date of")
    page.choose("No", visible: :all)
    page.click_button("Continue")

    # expect(page).to be_axe_clean
    # TODO: aria-expanded
    expect(page.current_path).to eq("/registration-interest")
    page.choose("Yes", visible: :all)
    page.fill_in "Email address", with: "user@example.com"
    page.click_button("Continue")

    expect(page.current_path).to eq("/registration-interest/confirm")
    expect(page).to have_text("We’ll send an email to user@example.com when registration reopens.")

    expect(RegistrationInterest.count).to eql(1)
  end

  scenario "Chooses not to sign up for notifications via NPQ registration path" do
    visit "/"

    expect(page).to have_text("Before you start")
    page.click_link("Start now")

    expect(page).to be_axe_clean
    expect(page).to have_text("Have you agreed a start date of")
    page.choose("No", visible: :all)
    page.click_button("Continue")

    # expect(page).to be_axe_clean
    # TODO: aria-expanded
    expect(page.current_path).to eq("/registration-interest")
    page.choose("No", visible: :all)
    page.click_button("Continue")

    expect(page).to be_axe_clean
    expect(page.current_path).to eq("/registration-interest/no-notification")
    expect(page).to have_text("You will not get an email alert")

    expect(RegistrationInterest.count).to eql(0)
  end

  scenario "Sign up to notification with direct link" do
    visit "/registration-interest/sign-up"

    expect(page).to be_axe_clean
    expect(page).to have_text("What’s your email address")
    page.fill_in "What’s your email address", with: "user@example.com"
    page.click_button("Confirm")

    expect(page).to be_axe_clean
    expect(page.current_path).to eq("/registration-interest/sign-up/confirm")
    expect(page).to have_text("We’ll send an email to user@example.com when registration reopens.")

    expect(RegistrationInterest.count).to eql(1)
  end
end
