require "rails_helper"

RSpec.feature "Happy journey", type: :feature do
  scenario "complete entire journey via happy path" do
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

    expect(page).to have_text("If you don’t know what your teacher reference number")
    page.click_link("Back")

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

    expect(page).to have_text("Confirm email")
    expect(page).to have_text("user@example.com")
  end
end
