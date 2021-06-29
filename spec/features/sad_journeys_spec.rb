require "rails_helper"

RSpec.feature "Sad journeys", type: :feature do
  scenario "DQT mismatch" do
    visit "/"
    expect(page).to have_text("Before you start")

    page.click_link("Start now")

    expect(page).to have_text("Have you already chosen an NPQ and provider?")
    page.choose("Yes, I have chosen my NPQ and provider")
    page.click_button("Continue")

    expect(page).to have_text("Sharing your NPQ information")
    page.check("Yes, I agree my information can be shared")
    page.click_button("Continue")

    expect(page).to have_text("Teacher reference number")
    page.choose("Yes, I know my TRN")
    page.click_button("Continue")

    expect(page).to have_text("Name changes")
    page.choose("No, I have the same name")
    page.click_button("Continue")

    expect(page.current_path).to include("contact-details")
    expect(page).to have_text("Email details")
    page.fill_in "Email address", with: "user@example.com"
    page.click_button("Continue")

    expect(page).to have_text("Confirm your code")
    expect(page).to have_text("user@example.com")
    page.fill_in "Enter your code", with: "000000"
    page.click_button("Continue")

    expect(page).to have_text("Confirm your code")
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

    expect(page).to have_text("Check your details")
    page.fill_in "Teacher reference number (TRN)", with: "1234567"
    page.fill_in "Full name", with: "John Doeeeeee"
    page.fill_in "Day", with: "13"
    page.fill_in "Month", with: "12"
    page.fill_in "Year", with: "1980"
    page.click_button("Continue")

    expect(page).to have_text("We cannot find your details")
    page.click_link("Try again")

    expect(page).to have_text("Check your details")
  end

  scenario "school not in england" do
    visit "/"
    expect(page).to have_text("Before you start")

    page.click_link("Start now")

    expect(page).to have_text("Have you already chosen an NPQ and provider?")
    page.choose("Yes, I have chosen my NPQ and provider")
    page.click_button("Continue")

    expect(page).to have_text("Sharing your NPQ information")
    page.check("Yes, I agree my information can be shared")
    page.click_button("Continue")

    expect(page).to have_text("Teacher reference number")
    page.choose("Yes, I know my TRN")
    page.click_button("Continue")

    expect(page).to have_text("Name changes")
    page.choose("No, I have the same name")
    page.click_button("Continue")

    expect(page.current_path).to include("contact-details")
    expect(page).to have_text("Email details")
    page.fill_in "Email address", with: "user@example.com"
    page.click_button("Continue")

    expect(page).to have_text("Confirm your code")
    expect(page).to have_text("user@example.com")
    page.fill_in "Enter your code", with: "000000"
    page.click_button("Continue")

    expect(page).to have_text("Confirm your code")
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
      .to_return(status: 200, body: dqt_response_body(trn: "1234567", date_of_birth: "1980-12-13"), headers: {})

    expect(page).to have_text("Check your details")
    page.fill_in "Teacher reference number (TRN)", with: "1234567"
    page.fill_in "Full name", with: "John Doe"
    page.fill_in "Day", with: "13"
    page.fill_in "Month", with: "12"
    page.fill_in "Year", with: "1980"
    page.click_button("Continue")

    expect(page).to have_text("Choose your NPQ")
    page.choose("NPQ for Senior Leadership (NPQSL)")
    page.click_button("Continue")

    expect(page).to have_text("Choose your provider")
    page.choose("Teach First")
    page.click_button("Continue")

    School.create!(urn: 100_000, name: "open welsh school", county: "Wrexham", establishment_status_code: "1", establishment_type_code: "30")

    expect(page).to have_text("Find your school")
    page.fill_in "School location", with: "wrexham"
    page.click_button("Continue")

    expect(page).to have_text("Choose your school")
    within ".npq-js-hidden" do
      page.fill_in "Enter your school name", with: "open"
    end
    page.click_button("Continue")

    expect(page).to have_text("Choose your school")
    page.choose "open welsh school"
    page.click_button("Continue")

    expect(page).to have_text("School must be in England")
    page.click_link("Back")

    expect(page).to have_text("Choose your school")
  end

  scenario "Not chosen DQT or provider" do
    visit "/"
    expect(page).to have_text("Before you start")

    page.click_link("Start now")
    expect(page).to have_text("Have you already chosen an NPQ and provider?")
    page.choose("No, I don't know my NPQ and provider")
    page.click_button("Continue")

    expect(page).to have_text("Choosing an NPQ and Provider")
  end
end
