require "rails_helper"

RSpec.feature "Happy journeys", type: :feature do
  scenario "registration journey via using old name and not headship" do
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
    page.choose("I need a reminder", visible: :all)
    page.click_button("Continue")

    expect(page).to be_axe_clean
    expect(page).to have_text("If you don’t know what your teacher reference number")
    page.click_link("Back")

    expect(page).to be_axe_clean
    expect(page.current_path).to eql("/registration/teacher-reference-number")
    page.choose("I do not have a TRN", visible: :all)
    page.click_button("Continue")

    expect(page).to be_axe_clean
    expect(page).to have_text("Get a Teacher Reference Number (TRN)")
    page.click_link("Back")

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
    expect(page).to have_text("Where is your school, college or academy trust?")
    page.fill_in "School or college location", with: "manchester"
    page.click_button("Continue")

    expect(page).to be_axe_clean
    expect(page).to have_text("Choose your school")
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
    expect(page).to have_text("DfE scholarship funding is not available")
    expect(page).to have_text("To be eligible for scholarship funding for")
    expect(page).to have_text("In England, Jersey, Guernsey or the Isle of Man")
    expect(page).to have_text("In a state-funded school, trust or 16 to 19 educational setting")
    page.click_link("Continue")

    expect(page).to be_axe_clean
    expect(page).to have_text("Funding")
    page.choose "My school or college is covering the cost", visible: :all
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
    expect(check_answers_page.summary_list["Full name"].value).to eql("John Doe")
    expect(check_answers_page.summary_list["TRN"].value).to eql("1234567")
    expect(check_answers_page.summary_list["Date of birth"].value).to eql("13 December 1980")
    expect(check_answers_page.summary_list.key?("National Insurance number")).to be_falsey
    expect(check_answers_page.summary_list["Email"].value).to eql("user@example.com")
    expect(check_answers_page.summary_list["Course"].value).to eql("NPQ for Senior Leadership (NPQSL)")
    expect(check_answers_page.summary_list.key?("Have you been a headteacher for two years or more?")).to be_falsey
    expect(check_answers_page.summary_list["School or college"].value).to eql("open manchester school")
    expect(check_answers_page.summary_list["How is your NPQ being paid for?"].value).to eql("My school or college is covering the cost")

    allow(ApplicationSubmissionJob).to receive(:perform_later).with(anything)

    page.click_button("Submit")

    expect(page).to be_axe_clean
    expect(page).to have_text("Your initial registration is complete")
    expect(page).to_not have_text("The Early Headship Coaching Offer is a package of structured face-to-face support for new headteachers.")
  end

  scenario "registration journey via using same name" do
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
          nino: "AB123456C",
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
    page.fill_in "National Insurance number (optional)", with: "AB123456C"
    page.click_button("Continue")

    School.create!(urn: 100_000, name: "open manchester school", address_1: "street 1", town: "manchester", establishment_status_code: "1")
    School.create!(urn: 100_001, name: "closed manchester school", address_1: "street 2", town: "manchester", establishment_status_code: "2")
    School.create!(urn: 100_002, name: "open newcastle school", address_1: "street 3", town: "newcastle", establishment_status_code: "1")

    expect(page).to be_axe_clean
    expect(page).to have_text("Where is your school, college or academy trust?")
    page.fill_in "School or college location", with: "manchester"
    page.click_button("Continue")

    expect(page).to be_axe_clean
    expect(page).to have_text("Choose your school")
    expect(page).to have_text("Please choose from schools and colleges located in manchester")
    within ".npq-js-reveal" do
      page.fill_in "Enter your school, college or trust name", with: "open"
    end

    expect(page).to have_content("open manchester school")
    page.find("#school-picker__option--0").click
    page.click_button("Continue")

    expect(page).to be_axe_clean
    expect(page).to have_text("What are you applying for?")
    page.choose("NPQ for Headship (NPQH)", visible: :all)
    page.click_button("Continue")

    expect(page).to be_axe_clean
    expect(page).to have_text("DfE scholarship funding is not available")
    expect(page).to have_text("In England, Jersey, Guernsey or the Isle of Man")
    expect(page).to have_text("In a state-funded school, trust or 16 to 19 educational setting")
    page.click_link("Continue")

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
    expect(check_answers_page.summary_list["Full name"].value).to eql("John Doe")
    expect(check_answers_page.summary_list["TRN"].value).to eql("1234567")
    expect(check_answers_page.summary_list["Date of birth"].value).to eql("13 December 1980")
    expect(check_answers_page.summary_list["National Insurance number"].value).to eql("AB123456C")
    expect(check_answers_page.summary_list["Email"].value).to eql("user@example.com")
    expect(check_answers_page.summary_list["Course"].value).to eql("NPQ for Headship (NPQH)")
    expect(check_answers_page.summary_list["Lead provider"].value).to eql("Teach First")
    expect(check_answers_page.summary_list["School or college"].value).to eql("open manchester school")
    expect(check_answers_page.summary_list["How is your NPQ being paid for?"].value).to eql("My trust is paying")

    allow(ApplicationSubmissionJob).to receive(:perform_later).with(anything)

    page.click_button("Submit")

    expect(page).to be_axe_clean
    expect(page).to have_text("Your initial registration is complete")
    expect(page).to_not have_text("The Early Headship Coaching Offer is a package of structured face-to-face support for new headteachers.")

    expect(User.count).to eql(1)

    user = User.last

    expect(user.email).to eql("user@example.com")
    expect(user.full_name).to eql("John Doe")
    expect(user.trn).to eql("1234567")
    expect(user.trn_verified).to be_truthy
    expect(user.trn_auto_verified).to be_truthy
    expect(user.date_of_birth).to eql(Date.new(1980, 12, 13))
    expect(user.national_insurance_number).to be_blank

    expect(user.applications.count).to eql(1)

    application = user.applications.first

    expect(application.eligible_for_funding).to be_falsey
    expect(application.funding_choice).to eql("trust")

    visit "/account"

    expect(page).to have_text("Teach First")
    expect(page).to have_text("NPQ for Headship (NPQH)")

    visit "/registration/share-provider"

    expect(page).to have_content("Before you start")
  end

  scenario "registration journey when outside of catchment area" do
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
    page.choose("Another country", visible: :all)
    within "[data-module='app-country-autocomplete'" do
      page.fill_in "Which country do you teach in?", with: "Falk"
    end

    expect(page).to have_content("Falkland Islands")
    page.find("#registration-wizard-teacher-catchment-country-field__option--0").click

    page.click_button("Continue")

    expect(page.current_path).to eql("/registration/work-in-school")
    page.choose("Yes", visible: :all)
    page.click_button("Continue")

    expect(page).to be_axe_clean
    expect(page.current_path).to eql("/registration/teacher-reference-number")
    page.choose("I need a reminder", visible: :all)
    page.click_button("Continue")

    expect(page).to be_axe_clean
    expect(page).to have_text("If you don’t know what your teacher reference number")
    page.click_link("Back")

    expect(page).to be_axe_clean
    expect(page.current_path).to eql("/registration/teacher-reference-number")
    page.choose("I do not have a TRN", visible: :all)
    page.click_button("Continue")

    expect(page).to be_axe_clean
    expect(page).to have_text("Get a Teacher Reference Number (TRN)")
    page.click_link("Back")

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
    page.choose("No", visible: :all)
    page.click_button("Continue")

    expect(page).to be_axe_clean
    expect(page).to have_text("What are you applying for?")
    page.choose("NPQ for Senior Leadership (NPQSL)", visible: :all)
    page.click_button("Continue")

    expect(page).to be_axe_clean
    expect(page).to have_text("DfE scholarship funding is not available")
    expect(page).to have_text("To be eligible for scholarship funding for")
    expect(page).to have_text("In England, Jersey, Guernsey or the Isle of Man")
    expect(page).to have_text("In a state-funded school, trust or 16 to 19 educational setting")
    page.click_link("Continue")

    expect(page).to be_axe_clean
    expect(page).to have_text("How is your course being paid for?")
    page.choose "I am paying", visible: :all
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
    expect(check_answers_page.summary_list["Full name"].value).to eql("John Doe")
    expect(check_answers_page.summary_list["TRN"].value).to eql("1234567")
    expect(check_answers_page.summary_list["Date of birth"].value).to eql("13 December 1980")
    expect(check_answers_page.summary_list.key?("National Insurance number")).to be_falsey
    expect(check_answers_page.summary_list["Email"].value).to eql("user@example.com")
    expect(check_answers_page.summary_list["Course"].value).to eql("NPQ for Senior Leadership (NPQSL)")
    expect(check_answers_page.summary_list.key?("Have you been a headteacher for two years or more?")).to be_falsey
    expect(check_answers_page.summary_list["How is your NPQ being paid for?"].value).to eql("I am paying")

    allow(ApplicationSubmissionJob).to receive(:perform_later).with(anything)

    page.click_button("Submit")

    expect(page).to be_axe_clean
  end

  scenario "registration journey while not currently working at school" do
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
    page.choose("No", visible: :all)
    page.click_button("Continue")

    expect(page).to be_axe_clean
    expect(page).to have_text("What are you applying for?")
    page.choose("NPQ for Senior Leadership (NPQSL)", visible: :all)
    page.click_button("Continue")

    expect(page).to be_axe_clean
    expect(page).to have_text("Tell us about where you work")
    page.fill_in "Name of employer", with: "Big company"
    page.fill_in "Role", with: "Trainer"
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

  scenario "registration journey while working at public nursery" do
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
    expect(page).to have_text("Do you work in a nursery?")
    page.choose("Yes", visible: :all)
    page.click_button("Continue")

    expect(page).to be_axe_clean
    expect(page).to have_text("What kind of nursery do you work in?")
    public_nursery_type = [
      "Local authority maintained nursery",
      "Preschool class that's part of a school",
    ].sample
    page.choose(public_nursery_type, visible: :all)
    page.click_button("Continue")

    expect(page).to be_axe_clean
    expect(page).to have_text("Where is your nursery?")
    page.fill_in "Nursery location", with: "manchester"
    page.click_button("Continue")

    expect(page).to be_axe_clean
    expect(page).to have_text("Choose your nursery")
    expect(page).to have_text("Choose from nurseries located in manchester")
    within ".npq-js-reveal" do
      page.fill_in "Enter your nursery name", with: "open"
    end

    expect(page).to have_content("open manchester school")
    page.find("#nursery-picker__option--0").click
    page.click_button("Continue")

    expect(page).to be_axe_clean
    expect(page).to have_text("What are you applying for?")
    page.choose("NPQ for Senior Leadership (NPQSL)", visible: :all) # Needs changing to an early years course once added
    page.click_button("Continue")

    expect(page).to have_text("DfE scholarship funding is not available")
    expect(page).to have_text("To be eligible for scholarship funding for")
    expect(page).to have_text("In England, Jersey, Guernsey or the Isle of Man")
    expect(page).to have_text("In a state-funded school, trust or 16 to 19 educational setting")
    page.click_link("Continue")

    expect(page).to be_axe_clean
    expect(page).to have_text("How is your course being paid for?")
    page.choose "My employer is paying", visible: :all
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

  scenario "registration journey while working at private nursery" do
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
    expect(page).to have_text("Do you work in a nursery?")
    page.choose("Yes", visible: :all)
    page.click_button("Continue")

    expect(page).to be_axe_clean
    expect(page).to have_text("What kind of nursery do you work in?")
    page.choose("Private nursery", visible: :all)
    page.click_button("Continue")

    expect(page).to be_axe_clean
    expect(page).to have_text("Do you have an Ofsted unique reference number (URN)?")
    page.choose("Yes", visible: :all)
    page.click_button("Continue")

    PrivateChildcareProvider.create!(provider_urn: "EY123456", provider_name: "searchable childcare provider", address_1: "street 1", town: "manchester")

    expect(page).to be_axe_clean
    expect(page).to have_text("Enter your or your employer's URN")
    within ".npq-js-reveal" do
      page.fill_in "private-childcare-provider-picker", with: "EY123"
    end

    expect(page).to have_content("EY123456 - searchable childcare provider - street 1, manchester")
    page.find("#private-childcare-provider-picker__option--0").click
    page.click_button("Continue")

    expect(page).to be_axe_clean
    expect(page).to have_text("What are you applying for?")
    page.choose("NPQ for Senior Leadership (NPQSL)", visible: :all) # Needs changing to an early years course once added
    page.click_button("Continue")

    expect(page).to be_axe_clean
    expect(page).to have_text("If your provider accepts your application, you’ll qualify for DfE funding.")
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
    expect(check_answers_page.summary_list["Full name"].value).to eql("John Doe")
    expect(check_answers_page.summary_list["TRN"].value).to eql("1234567")
    expect(check_answers_page.summary_list["Date of birth"].value).to eql("13 December 1980")
    expect(check_answers_page.summary_list.key?("National Insurance number")).to be_falsey
    expect(check_answers_page.summary_list["Email"].value).to eql("user@example.com")
    expect(check_answers_page.summary_list["Course"].value).to eql("NPQ for Senior Leadership (NPQSL)")
    expect(check_answers_page.summary_list.key?("Have you been a headteacher for two years or more?")).to be_falsey
    expect(check_answers_page.summary_list.key?("School or college")).to be_falsey
    expect(check_answers_page.summary_list.key?("How is your NPQ being paid for?")).to be_falsey

    allow(ApplicationSubmissionJob).to receive(:perform_later).with(anything)

    page.click_button("Submit")

    expect(page).to be_axe_clean
  end
end
