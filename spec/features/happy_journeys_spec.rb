require "rails_helper"

RSpec.feature "Happy journeys", type: :feature do
  scenario "registration journey via using old name and not headship" do
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
    page.choose("I don't have a TRN")
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
    page.click_button("Continue")

    code = ActionMailer::Base.deliveries.last[:personalisation].unparsed_value[:code]

    page.fill_in "Enter your code", with: code
    page.click_button("Continue")

    stub_request(:get, "https://ecf-app.gov.uk/api/v1/dqt-records/1234567890")
      .with(
        headers: {
          "Authorization" => "Bearer ECFAPPBEARERTOKEN",
        },
      )
      .to_return(status: 200, body: dqt_response_body(trn: "1234567890", date_of_birth: "1980-12-13"), headers: {})

    expect(page).to have_text("Qualified teacher check")
    page.fill_in "Teacher reference number (TRN)", with: "1234567890"
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

    expect(page).to have_text("Your delivery partner")
    expect(page).to have_text("Do you know which partner Teach First is using?")
    page.choose("Yes, I know which delivery partner will be used")
    page.click_button("Continue")

    expect(page).to have_text("Select your delivery partner")
    page.click_button("Continue")

    School.create!(urn: 100_000, name: "open manchester school", address_1: "street 1", town: "manchester", establishment_status_code: "1")

    expect(page).to have_text("Find your school")
    page.fill_in "School location", with: "manchester"
    page.click_button("Continue")

    expect(page).to have_text("Choose your school")
    expect(page).to have_text("Please choose from schools located in manchester")
    page.fill_in "Enter your school name", with: "open"
    page.click_button("Continue")

    expect(page).to have_text("Choose your school")
    expect(page).to have_text("street 1")
    page.choose "open manchester school"
    page.click_button("Continue")

    check_answers_page = CheckAnswersPage.new

    expect(check_answers_page).to be_displayed
    expect(check_answers_page.summary_list["Full name"].value).to eql("John Doe")
    expect(check_answers_page.summary_list["TRN"].value).to eql("1234567890")
    expect(check_answers_page.summary_list["Date of birth"].value).to eql("December 13, 1980")
    expect(check_answers_page.summary_list.key?("National Insurance number")).to be_falsey
    expect(check_answers_page.summary_list["Email"].value).to eql("user@example.com")
    expect(check_answers_page.summary_list["NPQ"].value).to eql("NPQ for Senior Leadership (NPQSL)")
    expect(check_answers_page.summary_list.key?("Have you been a headteacher for two years or more?")).to be_falsey
    expect(check_answers_page.summary_list["School"].value).to eql("open manchester school")
    page.click_button("Submit")
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

    stub_request(:get, "https://ecf-app.gov.uk/api/v1/dqt-records/1234567890")
      .with(
        headers: {
          "Authorization" => "Bearer ECFAPPBEARERTOKEN",
        },
      )
      .to_return(status: 200, body: dqt_response_body(trn: "1234567890", date_of_birth: "1980-12-13"), headers: {})

    expect(page).to have_text("Qualified teacher check")
    page.fill_in "Teacher reference number (TRN)", with: "1234567890"
    page.fill_in "Full name", with: "John Doe"
    page.fill_in "Day", with: "13"
    page.fill_in "Month", with: "12"
    page.fill_in "Year", with: "1980"
    page.fill_in "National Insurance number (optional)", with: "AB123456C"
    page.click_button("Continue")

    expect(page).to have_text("Choose your NPQ")
    page.choose("NPQ for Headship (NPQH)")
    page.click_button("Continue")

    expect(page).to have_text("How long have you been a headteacher?")
    page.choose("Yes, I have been a headteacher for two years or more")
    page.click_button("Continue")

    expect(page).to have_text("Choose your provider")
    page.choose("Teach First")
    page.click_button("Continue")

    expect(page).to have_text("Your delivery partner")
    page.choose("Yes, I know which delivery partner will be used")
    page.click_button("Continue")

    expect(page).to have_text("Select your delivery partner")
    page.click_button("Continue")

    School.create!(urn: 100_000, name: "open manchester school", address_1: "street 1", town: "manchester", establishment_status_code: "1")
    School.create!(urn: 100_001, name: "closed manchester school", address_1: "street 2", town: "manchester", establishment_status_code: "2")
    School.create!(urn: 100_002, name: "open newcastle school", address_1: "street 3", town: "newcastle", establishment_status_code: "1")

    expect(page).to have_text("Find your school")
    page.fill_in "School location", with: "manchester"
    page.click_button("Continue")

    expect(page).to have_text("Choose your school")
    expect(page).to have_text("Please choose from schools located in manchester")
    page.fill_in "Enter your school name", with: "open"
    page.click_button("Continue")

    expect(page).to have_text("Choose your school")
    expect(page).to have_text("street 1")
    page.choose "open manchester school"
    page.click_button("Continue")

    check_answers_page = CheckAnswersPage.new

    expect(check_answers_page).to be_displayed
    expect(check_answers_page.summary_list["Full name"].value).to eql("John Doe")
    expect(check_answers_page.summary_list["TRN"].value).to eql("1234567890")
    expect(check_answers_page.summary_list["Date of birth"].value).to eql("December 13, 1980")
    expect(check_answers_page.summary_list["National Insurance number"].value).to eql("AB123456C")
    expect(check_answers_page.summary_list["Email"].value).to eql("user@example.com")
    expect(check_answers_page.summary_list["NPQ"].value).to eql("NPQ for Headship (NPQH)")
    expect(check_answers_page.summary_list["Have you been a headteacher for two years or more?"].value).to eql("Yes")
    expect(check_answers_page.summary_list["Lead provider"].value).to eql("Teach First")
    expect(check_answers_page.summary_list["School"].value).to eql("open manchester school")
    page.click_link("Change Have you been a headteacher for two years or more?")

    expect(page).to have_text("How long have you been a headteacher?")
    page.choose("No, I’m not a headteacher or have been a headteacher for less than two years")
    page.click_button("Continue")

    expect(check_answers_page).to be_displayed
    expect(check_answers_page.summary_list["Have you been a headteacher for two years or more?"].value).to eql("No")

    page.click_button("Submit")

    expect(page).to have_text("Account created")

    expect(User.count).to eql(1)

    user = User.last

    expect(user.email).to eql("user@example.com")
    expect(user.full_name).to eql("John Doe")
    expect(user.trn).to eql("1234567890")

    expect(user.applications.count).to eql(1)

    visit "/account"

    expect(page).to have_text("Teach First")
    expect(page).to have_text("NPQ for Headship (NPQH)")
  end
end
