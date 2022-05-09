require "rails_helper"

RSpec.feature "Sad journeys", type: :feature do
  scenario "DQT mismatch" do
    visit "/"
    expect(page).to have_text("Before you start")
    page.click_link("Start now")

    expect(page).to be_axe_clean
    expect(page).to have_text("Have you agreed a start date of")
    page.choose("Yes", visible: :all)
    page.click_button("Continue")

    expect(page).to be_axe_clean
    expect(page).to have_text("Have you already chosen an NPQ and provider?")
    page.choose("Yes, I have chosen my NPQ and provider", visible: :all)
    page.click_button("Continue")

    # expect(page).to be_axe_clean
    # TODO: aria-expanded
    expect(page.current_path).to eql("/registration/teacher-catchment")
    page.choose("England", visible: :all)
    page.click_button("Continue")

    expect(page.current_path).to eql("/registration/work-in-school")
    page.choose("Yes", visible: :all)
    page.click_button("Continue")

    expect(page).to be_axe_clean
    expect(page.current_path).to eql("/registration/teacher-reference-number")
    page.choose("Yes", visible: :all)
    page.click_button("Continue")

    expect(page).to be_axe_clean
    expect(page.current_path).to include("contact-details")
    expect(page).to have_text("Email address")
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

    stub_request(:post, "https://ecf-app.gov.uk/api/v1/participant-validation")
      .with(
        headers: {
          "Authorization" => "Bearer ECFAPPBEARERTOKEN",
        },
        body: {
          trn: "1234567",
          date_of_birth: "1980-12-13",
          full_name: "John Doeeeeee",
          nino: "AB123456C",
        },
      )
      .to_return(status: 404, body: "", headers: {})

    expect(page).to be_axe_clean
    expect(page).to have_text("Check your details")
    page.fill_in "Teacher reference number (TRN)", with: "1234567"
    page.fill_in "Full name", with: "John Doeeeeee"
    page.fill_in "Day", with: "13"
    page.fill_in "Month", with: "12"
    page.fill_in "Year", with: "1980"
    page.fill_in "National Insurance number (optional)", with: "AB123456C"
    page.click_button("Continue")

    expect(page).to be_axe_clean
    expect(page).to have_text("We cannot find your details")
    page.click_link("Try again")

    expect(page).to be_axe_clean
    expect(page).to have_text("Check your details")
    page.click_button("Continue")

    expect(page).to have_text("We cannot find your details")
    page.click_link("Continue registration")

    School.create!(urn: 100_000, name: "open manchester school", address_1: "street 1", town: "manchester", establishment_status_code: "1")
    School.create!(urn: 100_001, name: "closed manchester school", address_1: "street 2", town: "manchester", establishment_status_code: "2")
    School.create!(urn: 100_002, name: "open newcastle school", address_1: "street 3", town: "newcastle", establishment_status_code: "1")

    expect(page).to be_axe_clean
    expect(page).to have_text("Where is your school, college or academy trust?")
    page.fill_in "School or college location", with: "manchester"
    page.click_button("Continue")

    expect(page).to be_axe_clean
    expect(page).to have_text("Choose your school, college or academy trust")
    expect(page).to have_text("Please choose from schools and colleges located in manchester")
    within ".npq-js-reveal" do
      page.fill_in "Enter your school, college or trust name", with: "open"
    end

    expect(page).to have_content("open manchester school")
    page.find("#school-picker__option--0").click
    page.click_button("Continue")

    expect(page).to be_axe_clean
    expect(page).to have_text("What are you applying for?")
    page.choose("NPQ for Senior Leadership (NPQSL)", visible: :all)
    page.click_button("Continue")

    expect(page).to be_axe_clean
    expect(page).to have_text("Funding")
    page.choose "My trust is paying", visible: :all
    page.click_button("Continue")

    expect(page).to be_axe_clean
    expect(page).to have_text("Select your provider")
    page.choose("Teach First", visible: :all)
    page.click_button("Continue")

    expect(page).to be_axe_clean
    expect(page).to have_text("Sharing your NPQ information")
    page.check("Yes, I agree my information can be shared", visible: :all)
    page.click_button("Continue")

    check_answers_page = CheckAnswersPage.new

    expect(page).to be_axe_clean
    expect(check_answers_page).to be_displayed
    expect(check_answers_page.summary_list["Full name"].value).to eql("John Doeeeeee")
    expect(check_answers_page.summary_list["TRN"].value).to eql("1234567")
    expect(check_answers_page.summary_list["Date of birth"].value).to eql("13 December 1980")
    expect(check_answers_page.summary_list["National Insurance number"].value).to eql("AB123456C")
    expect(check_answers_page.summary_list["Email"].value).to eql("user@example.com")
    expect(check_answers_page.summary_list["Course"].value).to eql("NPQ for Senior Leadership (NPQSL)")
    expect(check_answers_page.summary_list["Lead provider"].value).to eql("Teach First")
    expect(check_answers_page.summary_list["School or college"].value).to eql("open manchester school")
    expect(check_answers_page.summary_list["How is your NPQ being paid for?"].value).to eql("My trust is paying")

    allow(ApplicationSubmissionJob).to receive(:perform_later).with(anything)

    page.click_button("Submit")

    user = User.last

    expect(user.email).to eql("user@example.com")
    expect(user.full_name).to eql("John Doeeeeee")
    expect(user.trn).to eql("1234567")
    expect(user.trn_verified).to be_falsey
    expect(user.trn_auto_verified).to be_falsey
    expect(user.date_of_birth).to eql(Date.new(1980, 12, 13))
    expect(user.national_insurance_number).to eql("AB123456C")
  end

  scenario "school not in england" do
    visit "/"
    expect(page).to have_text("Before you start")
    page.click_link("Start now")

    expect(page).to be_axe_clean
    expect(page).to have_text("Have you agreed a start date of")
    page.choose("Yes", visible: :all)
    page.click_button("Continue")

    expect(page).to be_axe_clean
    expect(page).to have_text("Have you already chosen an NPQ and provider?")
    page.choose("Yes, I have chosen my NPQ and provider", visible: :all)
    page.click_button("Continue")

    # expect(page).to be_axe_clean
    # TODO: aria-expanded
    expect(page.current_path).to eql("/registration/teacher-catchment")
    page.choose("England", visible: :all)
    page.click_button("Continue")

    expect(page.current_path).to eql("/registration/work-in-school")
    page.choose("Yes", visible: :all)
    page.click_button("Continue")

    expect(page).to be_axe_clean
    expect(page.current_path).to eql("/registration/teacher-reference-number")
    page.choose("Yes", visible: :all)
    page.click_button("Continue")

    expect(page).to be_axe_clean
    expect(page.current_path).to include("contact-details")
    expect(page).to have_text("Email address")
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

    stub_request(:post, "https://ecf-app.gov.uk/api/v1/participant-validation")
      .with(
        headers: {
          "Authorization" => "Bearer ECFAPPBEARERTOKEN",
        },
        body: {
          trn: "1234567",
          date_of_birth: "1980-12-13",
          full_name: "John Doe",
          nino: "",
        },
      )
      .to_return(status: 200, body: participant_validator_response, headers: {})

    expect(page).to be_axe_clean
    expect(page).to have_text("Check your details")
    page.fill_in "Teacher reference number (TRN)", with: "1234567"
    page.fill_in "Full name", with: "John Doe"
    page.fill_in "Day", with: "13"
    page.fill_in "Month", with: "12"
    page.fill_in "Year", with: "1980"
    page.click_button("Continue")

    School.create!(urn: 100_000, name: "open welsh school", county: "Wrexham", establishment_status_code: "1", establishment_type_code: "30")

    expect(page).to be_axe_clean
    expect(page).to have_text("Where is your school, college or academy trust?")
    page.fill_in "School or college location", with: "wrexham"
    page.click_button("Continue")

    expect(page).to be_axe_clean
    expect(page).to have_text("Choose your school")
    within ".npq-js-reveal" do
      page.fill_in "Enter your school, college or trust name", with: "open"
    end

    expect(page).to have_content("open welsh school")
    page.find("#school-picker__option--0").click
    page.click_button("Continue")

    expect(page).to be_axe_clean
    expect(page).to have_text("School or college must be in England")
    page.click_link("Back")

    expect(page).to be_axe_clean
    expect(page).to have_text("Choose your school")
  end

  scenario "Not chosen DQT or provider" do
    visit "/"
    expect(page).to have_text("Before you start")
    page.click_link("Start now")

    expect(page).to be_axe_clean
    expect(page).to have_text("Have you agreed a start date of")
    page.choose("Yes", visible: :all)
    page.click_button("Continue")

    expect(page).to be_axe_clean
    expect(page).to have_text("Have you already chosen an NPQ and provider?")
    page.choose("No, I don’t know my NPQ and provider", visible: :all)
    page.click_button("Continue")

    expect(page).to be_axe_clean
    expect(page).to have_text("Choosing an NPQ and Provider")
  end

  scenario "works in childcare but not in england" do
    visit "/"
    expect(page).to have_text("Before you start")
    page.click_link("Start now")

    expect(page).to be_axe_clean
    expect(page).to have_text("Have you agreed a start date of")
    page.choose("Yes", visible: :all)
    page.click_button("Continue")

    expect(page).to be_axe_clean
    expect(page).to have_text("Have you already chosen an NPQ and provider?")
    page.choose("Yes, I have chosen my NPQ and provider", visible: :all)
    page.click_button("Continue")

    # expect(page).to be_axe_clean
    # TODO: aria-expanded
    expect(page.current_path).to eql("/registration/teacher-catchment")
    page.choose("Scotland", visible: :all)
    page.click_button("Continue")

    expect(page.current_path).to eql("/registration/work-in-school")
    page.choose("No", visible: :all)
    page.click_button("Continue")

    expect(page).to be_axe_clean
    expect(page.current_path).to eql("/registration/teacher-reference-number")
    page.choose("Yes", visible: :all)
    page.click_button("Continue")

    expect(page).to be_axe_clean
    expect(page.current_path).to include("contact-details")
    expect(page).to have_text("Email address")
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

    stub_request(:post, "https://ecf-app.gov.uk/api/v1/participant-validation")
      .with(
        headers: {
          "Authorization" => "Bearer ECFAPPBEARERTOKEN",
        },
        body: {
          trn: "1234567",
          date_of_birth: "1980-12-13",
          full_name: "John Doe",
          nino: "",
        },
      )
      .to_return(status: 200, body: participant_validator_response, headers: {})

    expect(page).to be_axe_clean
    expect(page).to have_text("Check your details")
    page.fill_in "Teacher reference number (TRN)", with: "1234567"
    page.fill_in "Full name", with: "John Doe"
    page.fill_in "Day", with: "13"
    page.fill_in "Month", with: "12"
    page.fill_in "Year", with: "1980"
    page.click_button("Continue")

    School.create!(urn: 100_000, name: "open manchester school", address_1: "street 1", town: "manchester", establishment_status_code: "1")

    expect(page).to be_axe_clean
    expect(page).to have_text("Do you work in early years or childcare?")
    page.choose("Yes", visible: :all)
    page.click_button("Continue")

    expect(page).to be_axe_clean
    expect(page).to have_text("What are you applying for?")
    page.choose("NPQ for Senior Leadership (NPQSL)", visible: :all) # Needs changing to an early years course once added
    page.click_button("Continue")

    expect(page).to be_axe_clean
    expect(page).to have_text("How is your course being paid for?")
    page.choose "My employer is paying", visible: :all
    page.click_button("Continue")

    expect(page).to be_axe_clean
    expect(page).to have_text("Select your provider")
    page.choose("Teach First", visible: :all)
    page.click_button("Continue")

    expect(page).to be_axe_clean
    expect(page).to have_text("Tell us about where you work")
    page.fill_in "Name of employer", with: "Big company"
    page.fill_in "Role", with: "Trainer"
    page.click_button("Continue")

    expect(page).to be_axe_clean
    expect(page).to have_text("Sharing your NPQ information")
    page.check("Yes, I agree my information can be shared", visible: :all)
    page.click_button("Continue")

    check_answers_page = CheckAnswersPage.new

    expect(page).to be_axe_clean
    expect(check_answers_page).to be_displayed
    expect(check_answers_page.summary_list["Full name"].value).to eql("John Doe")
    expect(check_answers_page.summary_list["TRN"].value).to eql("1234567")
    expect(check_answers_page.summary_list["Date of birth"].value).to eql("13 December 1980")
    expect(check_answers_page.summary_list.key?("National Insurance number")).to be_falsey
    expect(check_answers_page.summary_list["Email"].value).to eql("user@example.com")
    expect(check_answers_page.summary_list["Course"].value).to eql("NPQ for Senior Leadership (NPQSL)")
    expect(check_answers_page.summary_list.key?("Have you been a headteacher for two years or more?")).to be_falsey
    expect(check_answers_page.summary_list.key?("School or college")).to be_falsey
    expect(check_answers_page.summary_list["How is your NPQ being paid for?"].value).to eql("My employer is paying")

    allow(ApplicationSubmissionJob).to receive(:perform_later).with(anything)

    page.click_button("Submit")

    expect(page).to be_axe_clean
  end
end
