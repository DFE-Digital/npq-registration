require "rails_helper"

RSpec.feature "Happy journeys", type: :feature do
  scenario "registration journey via using old name and not headship" do
    visit "/"
    expect(page).to have_text("Before you start")
    page.click_link("Start now")

    expect(page).to be_axe_clean
    expect(page).to have_text("Have you already chosen an NPQ and provider?")
    page.choose("Yes, I have chosen my NPQ and provider", visible: :all)
    page.click_button("Continue")

    expect(page).to be_axe_clean
    expect(page).to have_text("Sharing your NPQ information")
    page.check("Yes, I agree my information can be shared", visible: :all)
    page.click_button("Continue")

    expect(page).to be_axe_clean
    expect(page).to have_text("Teacher reference number")
    page.choose("No, I don’t know my TRN", visible: :all)
    page.click_button("Continue")

    expect(page).to be_axe_clean
    expect(page).to have_text("If you don’t know what your teacher reference number")
    page.click_link("Back")

    expect(page).to be_axe_clean
    expect(page).to have_text("Teacher reference number")
    page.choose("I don’t have a TRN", visible: :all)
    page.click_button("Continue")

    expect(page).to be_axe_clean
    expect(page).to have_text("Get a Teacher Reference Number (TRN)")
    page.click_link("Back")

    expect(page).to be_axe_clean
    expect(page).to have_text("Teacher reference number")
    page.choose("Yes, I know my TRN", visible: :all)
    page.click_button("Continue")

    expect(page).to be_axe_clean
    expect(page).to have_text("Name changes")
    page.choose("Yes, I have changed my name", visible: :all)
    page.click_button("Continue")

    expect(page).to be_axe_clean
    expect(page).to have_text("Updated name")
    page.choose("Not sure", visible: :all)
    page.click_button("Continue")

    expect(page).to be_axe_clean
    expect(page).to have_text("I don’t know if I updated my name")
    page.click_link("Back")

    expect(page).to be_axe_clean
    expect(page).to have_text("Updated name")
    page.choose("No, I have not updated my name", visible: :all)
    page.click_button("Continue")

    expect(page).to be_axe_clean
    expect(page).to have_text("Updating your name")
    page.choose("Change my name on the Teaching Regulation Agency records", visible: :all)
    page.click_button("Continue")

    expect(page).to be_axe_clean
    expect(page).to have_text("Change your details on the Teaching Regulation Agency records")
    page.click_link("Back")

    expect(page).to be_axe_clean
    expect(page).to have_text("Updating your name")
    page.choose("Register with my previous name", visible: :all)
    page.click_button("Continue")

    expect(page).to be_axe_clean
    expect(page.current_path).to include("contact-details")
    expect(page).to have_text("Email details")
    page.fill_in "Email address", with: "user@example.com"
    page.click_button("Continue")

    expect(page).to be_axe_clean
    expect(page).to have_text("Confirm your code")
    expect(page).to have_text("user@example.com")
    page.click_button("Continue")

    code = ActionMailer::Base.deliveries.last[:personalisation].unparsed_value[:code]

    expect(page).to be_axe_clean
    page.fill_in "Enter your code", with: code
    page.click_button("Continue")

    stub_request(:get, "https://ecf-app.gov.uk/api/v1/dqt-records/1234567")
      .with(
        headers: {
          "Authorization" => "Bearer ECFAPPBEARERTOKEN",
        },
      )
      .to_return(status: 200, body: dqt_response_body(trn: "1234567", date_of_birth: "1980-12-13"), headers: {})

    expect(page).to be_axe_clean
    expect(page).to have_text("Confirm your details")
    page.fill_in "Teacher reference number (TRN)", with: "1234567"
    page.fill_in "Full name", with: "John Doe"
    page.fill_in "Day", with: "13"
    page.fill_in "Month", with: "12"
    page.fill_in "Year", with: "1980"
    page.click_button("Continue")

    expect(page).to be_axe_clean
    expect(page).to have_text("Choose your NPQ")
    page.choose("NPQ for Senior Leadership (NPQSL)", visible: :all)
    page.click_button("Continue")

    expect(page).to be_axe_clean
    expect(page).to have_text("Choose your provider")
    page.choose("Teach First", visible: :all)
    page.click_button("Continue")

    School.create!(urn: 100_000, name: "open manchester school", address_1: "street 1", town: "manchester", establishment_status_code: "1")

    expect(page).to be_axe_clean
    expect(page).to have_text("Find your school")
    page.fill_in "School location", with: "manchester"
    page.click_button("Continue")

    expect(page).to be_axe_clean
    expect(page).to have_text("Choose your school")
    expect(page).to have_text("Please choose from schools located in manchester")
    within ".npq-js-reveal" do
      page.fill_in "Enter your school name", with: "open"
    end

    expect(page).to have_content("open manchester school")
    page.find("#school-picker__option--0").click
    page.click_button("Continue")

    expect(page).to be_axe_clean
    expect(page).to have_text("Funding your NPQ")
    page.choose "My school is paying", visible: :all
    page.click_button("Continue")

    check_answers_page = CheckAnswersPage.new

    expect(page).to be_axe_clean
    expect(check_answers_page).to be_displayed
    expect(check_answers_page.summary_list["Full name"].value).to eql("John Doe")
    expect(check_answers_page.summary_list["TRN"].value).to eql("1234567")
    expect(check_answers_page.summary_list["Date of birth"].value).to eql("December 13, 1980")
    expect(check_answers_page.summary_list.key?("National Insurance number")).to be_falsey
    expect(check_answers_page.summary_list["Email"].value).to eql("user@example.com")
    expect(check_answers_page.summary_list["NPQ"].value).to eql("NPQ for Senior Leadership (NPQSL)")
    expect(check_answers_page.summary_list.key?("Have you been a headteacher for two years or more?")).to be_falsey
    expect(check_answers_page.summary_list["School"].value).to eql("open manchester school")
    expect(check_answers_page.summary_list["How is your NPQ being paid for?"].value).to eql("My school is paying")

    allow(ApplicationSubmissionJob).to receive(:perform_later).with(anything)

    page.click_button("Submit")

    expect(page).to be_axe_clean
  end

  scenario "registration journey via using same name" do
    visit "/"
    expect(page).to have_text("Before you start")
    page.click_link("Start now")

    expect(page).to be_axe_clean
    expect(page).to have_text("Have you already chosen an NPQ and provider?")
    page.choose("Yes, I have chosen my NPQ and provider", visible: :all)
    page.click_button("Continue")

    expect(page).to be_axe_clean
    expect(page).to have_text("Sharing your NPQ information")
    page.check("Yes, I agree my information can be shared", visible: :all)
    page.click_button("Continue")

    expect(page).to be_axe_clean
    expect(page).to have_text("Teacher reference number")
    page.choose("Yes, I know my TRN", visible: :all)
    page.click_button("Continue")

    expect(page).to be_axe_clean
    expect(page).to have_text("Name changes")
    page.choose("No, I have the same name", visible: :all)
    page.click_button("Continue")

    expect(page).to be_axe_clean
    expect(page.current_path).to include("contact-details")
    expect(page).to have_text("Email details")
    page.fill_in "Email address", with: "user@example.com"
    page.click_button("Continue")

    expect(page).to be_axe_clean
    expect(page).to have_text("Confirm your code")
    expect(page).to have_text("user@example.com")
    page.fill_in "Enter your code", with: "000000"
    page.click_button("Continue")

    expect(page).to be_axe_clean
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

    expect(page).to be_axe_clean
    expect(page).to have_text("Confirm your details")
    page.fill_in "Teacher reference number (TRN)", with: "1234567"
    page.fill_in "Full name", with: "John Doe"
    page.fill_in "Day", with: "13"
    page.fill_in "Month", with: "12"
    page.fill_in "Year", with: "1980"
    page.fill_in "National Insurance number (optional)", with: "AB123456C"
    page.click_button("Continue")

    expect(page).to be_axe_clean
    expect(page).to have_text("Choose your NPQ")
    page.choose("NPQ for Headship (NPQH)", visible: :all)
    page.click_button("Continue")

    expect(page).to be_axe_clean
    expect(page).to have_text("How long have you been a headteacher?")
    page.choose("No, I have been a headteacher for more than 2 years", visible: :all)
    page.click_button("Continue")

    expect(page).to be_axe_clean
    expect(page).to have_text("Choose your provider")
    page.choose("Teach First", visible: :all)
    page.click_button("Continue")

    School.create!(urn: 100_000, name: "open manchester school", address_1: "street 1", town: "manchester", establishment_status_code: "1")
    School.create!(urn: 100_001, name: "closed manchester school", address_1: "street 2", town: "manchester", establishment_status_code: "2")
    School.create!(urn: 100_002, name: "open newcastle school", address_1: "street 3", town: "newcastle", establishment_status_code: "1")

    expect(page).to be_axe_clean
    expect(page).to have_text("Find your school")
    page.fill_in "School location", with: "manchester"
    page.click_button("Continue")

    expect(page).to be_axe_clean
    expect(page).to have_text("Choose your school")
    expect(page).to have_text("Please choose from schools located in manchester")
    within ".npq-js-reveal" do
      page.fill_in "Enter your school name", with: "open"
    end

    expect(page).to have_content("open manchester school")
    page.find("#school-picker__option--0").click
    page.click_button("Continue")

    expect(page).to be_axe_clean
    expect(page).to have_text("Funding your NPQ")
    page.choose "My trust is paying", visible: :all
    page.click_button("Continue")

    check_answers_page = CheckAnswersPage.new

    expect(page).to be_axe_clean
    expect(check_answers_page).to be_displayed
    expect(check_answers_page.summary_list["Full name"].value).to eql("John Doe")
    expect(check_answers_page.summary_list["TRN"].value).to eql("1234567")
    expect(check_answers_page.summary_list["Date of birth"].value).to eql("December 13, 1980")
    expect(check_answers_page.summary_list["National Insurance number"].value).to eql("AB123456C")
    expect(check_answers_page.summary_list["Email"].value).to eql("user@example.com")
    expect(check_answers_page.summary_list["NPQ"].value).to eql("NPQ for Headship (NPQH)")
    expect(check_answers_page.summary_list["How long have you been a headteacher?"].value).to eql("Yes over two years")
    expect(check_answers_page.summary_list["Lead provider"].value).to eql("Teach First")
    expect(check_answers_page.summary_list["School"].value).to eql("open manchester school")
    expect(check_answers_page.summary_list["How is your NPQ being paid for?"].value).to eql("My trust is paying")
    page.click_link("Change How long have you been a headteacher?")

    expect(page).to be_axe_clean
    expect(page).to have_text("How long have you been a headteacher?")
    page.choose("No, I am not a headteacher", visible: :all)
    page.click_button("Continue")

    expect(page).to be_axe_clean
    expect(check_answers_page).to be_displayed
    expect(check_answers_page.summary_list["How long have you been a headteacher?"].value).to eql("No")

    allow(ApplicationSubmissionJob).to receive(:perform_later).with(anything)

    page.click_button("Submit")

    expect(page).to be_axe_clean
    expect(page).to have_text("Initial registration complete")

    expect(User.count).to eql(1)

    user = User.last

    expect(user.email).to eql("user@example.com")
    expect(user.full_name).to eql("John Doe")
    expect(user.trn).to eql("1234567")
    expect(user.trn_verified).to be_truthy
    expect(user.date_of_birth).to eql(Date.new(1980, 12, 13))

    expect(user.applications.count).to eql(1)

    application = user.applications.first

    expect(application.eligible_for_funding).to be_falsey
    expect(application.funding_choice).to eql("trust")

    visit "/account"

    expect(page).to have_text("Teach First")
    expect(page).to have_text("NPQ for Headship (NPQH)")

    visit "/registration/share-provider"

    expect(page).to have_unchecked_field("Yes, I agree my information can be shared", visible: :all)
  end
end
