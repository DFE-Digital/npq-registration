require "rails_helper"

RSpec.feature "Happy journeys", type: :feature do
  scenario "registration journey via using old name" do
    visit "/"
    expect(page).to have_text("Before you start")

    page.click_link("Start now")

    expect(page).to have_text("Share choices with training provider")
    page.check("I agree my choices can be shared with my training provider")
    page.click_button("Continue")

    expect(page).to have_text("Teacher reference number")
    page.choose("No, I don't know my TRN")
    page.click_button("Continue")

    expect(page).to have_text("If you don’t know what your teacher reference number")
    page.click_link("Back")

    expect(page).to have_text("Teacher reference number")
    page.choose("No, I don't have a TRN")
    page.click_button("Continue")

    expect(page).to have_text("Get a Teacher Reference Number (TRN)")
    page.click_link("Back")

    expect(page).to have_text("Teacher reference number")
    page.choose("Yes, I know my TRN")
    page.click_button("Continue")

    expect(page).to have_text("Name changes")
    page.choose("Yes, I have changed my name")
    page.click_button("Continue")

    expect(page).to have_text("Updated name")
    page.choose("Not sure")
    page.click_button("Continue")

    expect(page).to have_text("I don't know if I updated my name")
    page.click_link("Back")

    expect(page).to have_text("Updated name")
    page.choose("No, I have not updated my name")
    page.click_button("Continue")

    expect(page).to have_text("Name not updated")
    page.choose("Change my name on the DQT")
    page.click_button("Continue")

    expect(page).to have_text("Change your details on the Database of Qualified Teachers (DQT)")
    page.click_link("Back")

    expect(page).to have_text("Name not updated")
    page.choose("Register with my old name")
    page.click_button("Continue")

    expect(page.current_path).to include("contact-details")
    expect(page).to have_text("Contact details")
    page.fill_in "Email address", with: "user@example.com"
    page.click_button("Continue")

    expect(page).to have_text("Confirm your contact details")
    expect(page).to have_text("user@example.com")
  end

  scenario "registration journey via using same name" do
    visit "/"
    expect(page).to have_text("Before you start")

    page.click_link("Start now")

    expect(page).to have_text("Share choices with training provider")
    page.check("I agree my choices can be shared with my training provider")
    page.click_button("Continue")

    expect(page).to have_text("Teacher reference number")
    page.choose("Yes, I know my TRN")
    page.click_button("Continue")

    expect(page).to have_text("Name changes")
    page.choose("No, I have the same name")
    page.click_button("Continue")

    expect(page.current_path).to include("contact-details")
    expect(page).to have_text("Contact details")
    page.fill_in "Email address", with: "user@example.com"
    page.click_button("Continue")

    expect(page).to have_text("Confirm your contact details")
    expect(page).to have_text("user@example.com")
    page.fill_in "Enter your code", with: "000000"
    page.click_button("Continue")

    expect(page).to have_text("Confirm your contact details")
    expect(page).to have_text("Code is not correct")

    code = ActionMailer::Base.deliveries.last[:personalisation].unparsed_value[:code]

    page.fill_in "Enter your code", with: code
    page.click_button("Continue")

    expect(page).to have_text("Qualified teacher check")
  end
end
