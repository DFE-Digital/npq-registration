require "rails_helper"

RSpec.feature "Sad journeys", type: :feature do
  scenario "DQT mismatch" do
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

    stub_request(:get, "https://ecf-app.gov.uk/api/v1/dqt-records/1234567")
      .with(
        headers: {
          "Authorization" => "Bearer ECFAPPBEARERTOKEN",
        },
      )
      .to_return(status: 200, body: dqt_response_body, headers: {})

    expect(page).to have_text("Qualified teacher check")
    page.fill_in "Teacher reference number (TRN)", with: "1234567"
    page.fill_in "First name", with: "John"
    page.fill_in "Last name", with: "Doe"
    page.fill_in "Day", with: "13"
    page.fill_in "Month", with: "12"
    page.fill_in "Year", with: "1980"
    page.click_button("Continue")

    expect(page).to have_text("We cannot find your details")
    page.click_link("Try again")

    expect(page).to have_text("Qualified teacher check")
  end
end
