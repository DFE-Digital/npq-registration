require "rails_helper"

RSpec.feature "Email confirmation", type: :feature do
  scenario "going back and changing their email address requires confirmation" do
    visit "/"
    page.click_link("Start now")
    page.choose("Yes, I have chosen my NPQ and provider")
    page.click_button("Continue")
    page.check("Yes, I agree my information can be shared")
    page.click_button("Continue")
    page.choose("Yes, I know my TRN")
    page.click_button("Continue")
    page.choose("No, I have the same name")
    page.click_button("Continue")
    page.fill_in "Email address", with: "user@example.com"
    page.click_button("Continue")

    code = ActionMailer::Base.deliveries.last[:personalisation].unparsed_value[:code]

    expect {
      page.click_link("I have not received an email")
    }.to change { ActionMailer::Base.deliveries.size }.by(1)
    expect(page).to have_content("Another email with confirmation details has been sent to user@example.com")
    expect(ActionMailer::Base.deliveries.last[:personalisation].unparsed_value[:code]).to eql(code)

    page.fill_in "Enter your code", with: code
    page.click_button("Continue")

    # goes back to email page and skips code page
    expect(page).to have_content("Check your details")
    page.click_link("Back")

    # skips code page as email already confirmed
    expect(page).to have_content("Email details")
    page.click_button("Continue")

    # change email address
    expect(page).to have_content("Check your details")
    page.click_link("Back")
    page.fill_in "Email address", with: "changed@example.com"
    page.click_button("Continue")

    code = ActionMailer::Base.deliveries.last[:personalisation].unparsed_value[:code]

    # must confirm again
    expect(page).to have_content("Confirm your code")
    expect(page.find_field("Enter your code").value).to be_blank
    page.fill_in "Enter your code", with: code
    page.click_button("Continue")

    expect(page).to have_content("Check your details")
  end
end
