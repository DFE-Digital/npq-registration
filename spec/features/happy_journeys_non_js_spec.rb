require "rails_helper"

RSpec.feature "Happy journeys", type: :feature do
  around do |example|
    Capybara.current_driver = :rack_test

    example.run

    Capybara.current_driver = Capybara.default_driver
  end

  scenario "registration journey via using old name and not headship" do
    visit "/"
    expect(page).to have_text("Before you start")
    page.click_link("Start now")

    expect(page).to have_text("Have you agreed a start date of")
    page.choose("Yes", visible: :all)
    page.click_button("Continue")

    expect(page).to have_text("Have you already chosen an NPQ and provider?")
    page.choose("Yes, I have chosen my NPQ and provider")
    page.click_button("Continue")

    expect(page.current_path).to eql("/registration/teacher-catchment")
    page.choose("England")
    page.click_button("Continue")

    expect(page.current_path).to eql("/registration/work-in-school")
    page.choose("Yes")
    page.click_button("Continue")

    expect(page.current_path).to eql("/registration/teacher-reference-number")
    page.choose("Yes, but I need to be reminded what it is")
    page.click_button("Continue")

    expect(page).to have_text("If you don’t know what your teacher reference number")
    page.click_link("Back")

    expect(page.current_path).to eql("/registration/teacher-reference-number")
    page.choose("No, I need to get a TRN")
    page.click_button("Continue")

    expect(page).to have_text("Get a Teacher Reference Number (TRN)")
    page.click_link("Back")

    expect(page.current_path).to eql("/registration/teacher-reference-number")
    page.choose("Yes, I know my TRN")
    page.click_button("Continue")

    expect(page.current_path).to include("contact-details")
    expect(page).to have_text("Email address")
    page.fill_in "Email address", with: "user@example.com"
    page.click_button("Continue")

    expect(page).to have_text("Confirm your code")
    expect(page).to have_text("user@example.com")
    page.click_button("Continue")

    code = ActionMailer::Base.deliveries.last[:personalisation].unparsed_value[:code]

    page.fill_in "Enter your code", with: code
    page.click_button("Continue")

    stub_request(:post, "https://ecf-app.gov.uk/api/v1/participant-validation")
      .with(
        headers: {
          "Authorization" => "Bearer ECFAPPBEARERTOKEN",
        },
        body: {
          trn: "12345",
          date_of_birth: "1980-12-13",
          full_name: "John Doe",
          nino: "",
        },
      )
      .to_return(status: 200, body: participant_validator_response(trn: "12345"), headers: {})

    expect(page).to have_text("Check your details")
    page.fill_in "Teacher reference number (TRN)", with: "RP12/345"
    page.fill_in "Full name", with: "John Doe"
    page.fill_in "Day", with: "13"
    page.fill_in "Month", with: "12"
    page.fill_in "Year", with: "1980"
    page.click_button("Continue")

    School.create!(
      urn: 100_000,
      name: "open manchester school",
      address_1: "street 1",
      town: "manchester",
      establishment_status_code: "1",
      establishment_type_code: "1",
      high_pupil_premium: true,
      number_of_pupils: 100,
    )

    expect(page).to have_text("Where is your school, college or academy trust?")
    page.fill_in "School or college location", with: "manchester"
    page.click_button("Continue")

    expect(page).to have_text("Choose your school, college or academy trust")
    expect(page).to have_text("Please choose from schools and colleges located in manchester")

    within ".npq-js-hidden" do
      page.fill_in "Enter your school, college or trust name", with: "open"
    end
    page.click_button("Continue")

    expect(page).to have_text("Choose your school")
    page.choose "open manchester school"
    page.click_button("Continue")

    expect(page).to have_text("What are you applying for?")
    page.choose("NPQ for Senior Leadership (NPQSL)")
    page.click_button("Continue")

    expect(page).to have_text("You may qualify for DfE scholarship funding")
    page.click_button("Continue")

    expect(page).to have_text("Choose your provider")
    page.choose("Teach First")
    page.click_button("Continue")

    expect(page).to have_text("Sharing your NPQ information")
    page.check("Yes, I agree my information can be shared")
    page.click_button("Continue")

    check_answers_page = CheckAnswersPage.new

    expect(check_answers_page).to be_displayed
    expect(check_answers_page.summary_list["Where do you work?"].value).to eql("England")
    expect(check_answers_page.summary_list["Do you work in a school or college?"].value).to eql("Yes")
    expect(check_answers_page.summary_list["Full name"].value).to eql("John Doe")
    expect(check_answers_page.summary_list["TRN"].value).to eql("RP12/345")
    expect(check_answers_page.summary_list["Date of birth"].value).to eql("13 December 1980")
    expect(check_answers_page.summary_list.key?("National Insurance number")).to be_falsey
    expect(check_answers_page.summary_list["Email"].value).to eql("user@example.com")
    expect(check_answers_page.summary_list["Course"].value).to eql("NPQ for Senior Leadership (NPQSL)")
    expect(check_answers_page.summary_list.key?("Have you been a headteacher for two years or more?")).to be_falsey
    expect(check_answers_page.summary_list["School or college"].value).to eql("open manchester school")

    allow(ApplicationSubmissionJob).to receive(:perform_later).with(anything)

    page.click_button("Submit")

    expect(User.count).to eql(1)

    user = User.last

    expect(user.email).to eql("user@example.com")
    expect(user.full_name).to eql("John Doe")
    expect(user.trn).to eql("0012345")
    expect(user.trn_verified).to be_truthy
    expect(user.trn_auto_verified).to be_truthy
    expect(user.date_of_birth).to eql(Date.new(1980, 12, 13))
    expect(user.national_insurance_number).to be_blank

    expect(user.applications.count).to eql(1)

    application = user.applications.first

    expect(application.eligible_for_funding).to be_truthy
    expect(application.funding_choice).to be_nil
    expect(application.course).to be_npqsl
    expect(application.headteacher_status).to be_nil
    expect(application.low_head_count_eligibility).to be_truthy

    visit "/"
    visit "/registration/confirmation"

    expect(page.current_path).to eql("/")
  end

  scenario "registration journey via using same name" do
    visit "/"
    expect(page).to have_text("Before you start")
    page.click_link("Start now")

    expect(page).to have_text("Have you agreed a start date of")
    page.choose("Yes", visible: :all)
    page.click_button("Continue")

    expect(page).to have_text("Have you already chosen an NPQ and provider?")
    page.choose("Yes, I have chosen my NPQ and provider")
    page.click_button("Continue")

    expect(page.current_path).to eql("/registration/teacher-catchment")
    page.choose("England")
    page.click_button("Continue")

    expect(page.current_path).to eql("/registration/work-in-school")
    page.choose("Yes")
    page.click_button("Continue")

    expect(page.current_path).to eql("/registration/teacher-reference-number")
    page.choose("Yes, I know my TRN")
    page.click_button("Continue")

    expect(page.current_path).to include("contact-details")
    expect(page).to have_text("Email address")
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

    expect(page).to have_text("Where is your school, college or academy trust?")
    page.fill_in "School or college location", with: "manchester"
    page.click_button("Continue")

    expect(page).to have_text("Choose your school, college or academy trust")
    expect(page).to have_text("Please choose from schools and colleges located in manchester")
    within ".npq-js-hidden" do
      page.fill_in "Enter your school, college or trust name", with: "open"
    end
    page.click_button("Continue")

    expect(page).to have_text("Choose your school, college or academy trust")
    page.choose "open manchester school"
    page.click_button("Continue")

    expect(page).to have_text("What are you applying for?")
    page.choose("NPQ for Headship (NPQH)")
    page.click_button("Continue")

    expect(page).to have_text("Funding")
    page.choose "My trust is paying"
    page.click_button("Continue")

    expect(page).to have_text("Choose your provider")
    page.choose("Teach First")
    page.click_button("Continue")

    expect(page).to have_text("Sharing your NPQ information")
    page.check("Yes, I agree my information can be shared")
    page.click_button("Continue")

    check_answers_page = CheckAnswersPage.new

    expect(check_answers_page).to be_displayed
    expect(check_answers_page.summary_list["Where do you work?"].value).to eql("England")
    expect(check_answers_page.summary_list["Do you work in a school or college?"].value).to eql("Yes")
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

    expect(page).to have_text("Your initial registration is complete")

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
    expect(application.course).to be_npqh
    expect(application.headteacher_status).to be_nil

    visit "/account"

    expect(page).to have_text("Teach First")
    expect(page).to have_text("NPQ for Headship (NPQH)")

    visit "/registration/check-answers"

    expect(page.current_path).to eql("/")
  end

  scenario "self funded ASO registration journey" do
    visit "/"
    expect(page).to have_text("Before you start")
    page.click_link("Start now")

    expect(page).to have_text("Have you agreed a start date of")
    page.choose("Yes", visible: :all)
    page.click_button("Continue")

    expect(page).to have_text("Have you already chosen an NPQ and provider?")
    page.choose("Yes, I have chosen my NPQ and provider")
    page.click_button("Continue")

    expect(page.current_path).to eql("/registration/teacher-catchment")
    page.choose("England")
    page.click_button("Continue")

    expect(page.current_path).to eql("/registration/work-in-school")
    page.choose("Yes")
    page.click_button("Continue")

    expect(page.current_path).to eql("/registration/teacher-reference-number")
    page.choose("Yes, I know my TRN")
    page.click_button("Continue")

    expect(page.current_path).to include("contact-details")
    expect(page).to have_text("Email address")
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

    expect(page).to have_text("Where is your school, college or academy trust?")
    page.fill_in "School or college location", with: "manchester"
    page.click_button("Continue")

    expect(page).to have_text("Choose your school, college or academy trust")
    expect(page).to have_text("Please choose from schools and colleges located in manchester")
    within ".npq-js-hidden" do
      page.fill_in "Enter your school, college or trust name", with: "open"
    end
    page.click_button("Continue")

    expect(page).to have_text("Choose your school, college or academy trust")
    page.choose "open manchester school"
    page.click_button("Continue")

    expect(page).to have_text("What are you applying for?")
    page.choose("Additional Support Offer for new headteachers")
    page.click_button("Continue")

    expect(page).to have_selector "h1", text: "Additional Support Offer for new headteachers"
    page.click_link("Continue")

    expect(page).to have_selector "h1", text: "Are you studying for, or have you completed an NPQ for Headship (NPQH)?"
    page.choose "None of the above"
    page.click_button("Continue")

    expect(page).to have_selector "h1", text: "You cannot register for the Additional Support Offer"
    page.click_link("Back")

    expect(page).to have_selector "h1", text: "Are you studying for, or have you completed an NPQ for Headship (NPQH)?"
    page.choose "I have completed an NPQH"
    page.click_button("Continue")

    expect(page).to have_selector "h1", text: "Are you a headteacher?"
    page.choose "No"
    page.click_button("Continue")

    expect(page).to have_selector "h1", text: "DfE scholarship funding not available"
    page.choose "No"
    page.click_button("Continue")

    expect(page).to have_selector "h1", text: "Contact your provider"
    page.click_link("Back")

    expect(page).to have_selector "h1", text: "DfE scholarship funding not available"
    page.choose "Yes, I will pay another way"
    page.click_button("Continue")

    expect(page).to have_selector "h1", text: "How is the Additional Support Offer being paid for?"
    page.choose "I am paying"
    page.click_button("Continue")

    expect(page).to have_text("Choose your provider")
    page.choose("Teach First")
    page.click_button("Continue")

    expect(page).to have_text("Sharing your NPQ information")
    page.check("Yes, I agree my information can be shared")
    page.click_button("Continue")

    check_answers_page = CheckAnswersPage.new

    expect(check_answers_page).to be_displayed
    expect(check_answers_page.summary_list["Where do you work?"].value).to eql("England")
    expect(check_answers_page.summary_list["Do you work in a school or college?"].value).to eql("Yes")
    expect(check_answers_page.summary_list["Full name"].value).to eql("John Doe")
    expect(check_answers_page.summary_list["TRN"].value).to eql("1234567")
    expect(check_answers_page.summary_list["Date of birth"].value).to eql("13 December 1980")
    expect(check_answers_page.summary_list["National Insurance number"].value).to eql("AB123456C")
    expect(check_answers_page.summary_list["Email"].value).to eql("user@example.com")
    expect(check_answers_page.summary_list["Course"].value).to eql("Additional Support Offer for new headteachers")
    expect(check_answers_page.summary_list["Lead provider"].value).to eql("Teach First")
    expect(check_answers_page.summary_list["School or college"].value).to eql("open manchester school")

    allow(ApplicationSubmissionJob).to receive(:perform_later).with(anything)

    page.click_button("Submit")

    expect(page).to have_text("Your initial registration is complete")

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

    expect(application.course).to be_aso
    expect(application.headteacher_status).to eql("no")
    expect(application.eligible_for_funding).to be_falsey
    expect(application.funding_choice).to eql("self")

    visit "/account"

    expect(page).to have_text("Teach First")
    expect(page).to have_text("Additional Support Offer for new headteachers")

    visit "/registration/check-answers"

    expect(page.current_path).to eql("/")
  end

  scenario "funded ASO registration journey" do
    visit "/"
    expect(page).to have_text("Before you start")
    page.click_link("Start now")

    expect(page).to have_text("Have you agreed a start date of")
    page.choose("Yes", visible: :all)
    page.click_button("Continue")

    expect(page).to have_text("Have you already chosen an NPQ and provider?")
    page.choose("Yes, I have chosen my NPQ and provider")
    page.click_button("Continue")

    expect(page.current_path).to eql("/registration/teacher-catchment")
    page.choose("England")
    page.click_button("Continue")

    expect(page.current_path).to eql("/registration/work-in-school")
    page.choose("Yes")
    page.click_button("Continue")

    expect(page.current_path).to eql("/registration/teacher-reference-number")
    page.choose("Yes, I know my TRN")
    page.click_button("Continue")

    expect(page.current_path).to include("contact-details")
    expect(page).to have_text("Email address")
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

    expect(page).to have_text("Check your details")
    page.fill_in "Teacher reference number (TRN)", with: "1234567"
    page.fill_in "Full name", with: "John Doe"
    page.fill_in "Day", with: "13"
    page.fill_in "Month", with: "12"
    page.fill_in "Year", with: "1980"
    page.fill_in "National Insurance number (optional)", with: "AB123456C"
    page.click_button("Continue")

    School.create!(urn: 100_000, name: "open manchester school", address_1: "street 1", town: "manchester", establishment_status_code: "1", establishment_type_code: "1")
    School.create!(urn: 100_001, name: "closed manchester school", address_1: "street 2", town: "manchester", establishment_status_code: "2")
    School.create!(urn: 100_002, name: "open newcastle school", address_1: "street 3", town: "newcastle", establishment_status_code: "1")

    expect(page).to have_text("Where is your school, college or academy trust?")
    page.fill_in "School or college location", with: "manchester"
    page.click_button("Continue")

    expect(page).to have_text("Choose your school, college or academy trust")
    expect(page).to have_text("Please choose from schools and colleges located in manchester")
    within ".npq-js-hidden" do
      page.fill_in "Enter your school, college or trust name", with: "open"
    end
    page.click_button("Continue")

    expect(page).to have_text("Choose your school, college or academy trust")
    page.choose "open manchester school"
    page.click_button("Continue")

    expect(page).to have_text("What are you applying for?")
    page.choose("Additional Support Offer for new headteachers")
    page.click_button("Continue")

    expect(page).to have_selector "h1", text: "Additional Support Offer for new headteachers"
    page.click_link("Continue")

    expect(page).to have_selector "h1", text: "Are you studying for, or have you completed an NPQ for Headship (NPQH)?"
    page.choose "None of the above"
    page.click_button("Continue")

    expect(page).to have_selector "h1", text: "You cannot register for the Additional Support Offer"
    page.click_link("Back")

    expect(page).to have_selector "h1", text: "Are you studying for, or have you completed an NPQ for Headship (NPQH)?"
    page.choose "I have completed an NPQH"
    page.click_button("Continue")

    expect(page).to have_selector "h1", text: "Are you a headteacher?"
    page.choose "Yes, I am a headteacher"
    page.click_button("Continue")

    expect(page).to have_selector "h1", text: "Are you in your first 2 years of a headship?"
    page.choose "Yes, I am in my first 2 years of a headship"
    page.click_button("Continue")

    expect(page).to have_selector "h1", text: "You may qualify for DfE scholarship funding"
    page.click_button("Continue")

    expect(page).to have_text("Choose your provider")
    page.choose("Teach First")
    page.click_button("Continue")

    expect(page).to have_text("Sharing your NPQ information")
    page.check("Yes, I agree my information can be shared")
    page.click_button("Continue")

    check_answers_page = CheckAnswersPage.new

    expect(check_answers_page).to be_displayed
    expect(check_answers_page.summary_list["Where do you work?"].value).to eql("England")
    expect(check_answers_page.summary_list["Do you work in a school or college?"].value).to eql("Yes")
    expect(check_answers_page.summary_list["Full name"].value).to eql("John Doe")
    expect(check_answers_page.summary_list["TRN"].value).to eql("1234567")
    expect(check_answers_page.summary_list["Date of birth"].value).to eql("13 December 1980")
    expect(check_answers_page.summary_list["National Insurance number"].value).to eql("AB123456C")
    expect(check_answers_page.summary_list["Email"].value).to eql("user@example.com")
    expect(check_answers_page.summary_list["Course"].value).to eql("Additional Support Offer for new headteachers")
    expect(check_answers_page.summary_list["Lead provider"].value).to eql("Teach First")
    expect(check_answers_page.summary_list["School or college"].value).to eql("open manchester school")

    allow(ApplicationSubmissionJob).to receive(:perform_later).with(anything)

    page.click_button("Submit")

    expect(page).to have_text("Your initial registration is complete")

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

    expect(application.course).to be_aso
    expect(application.headteacher_status).to eql("yes_in_first_two_years")
    expect(application.eligible_for_funding).to be_truthy
    expect(application.funding_choice).to be_nil
    expect(application.teacher_catchment).to eql("england")
    expect(application.teacher_catchment_country).to be_nil
    expect(application.low_head_count_eligibility).to be_falsey

    visit "/account"

    expect(page).to have_text("Teach First")
    expect(page).to have_text("Additional Support Offer for new headteachers")

    visit "/registration/check-answers"

    expect(page.current_path).to eql("/")
  end

  scenario "international teacher NPQH journey" do
    visit "/"
    expect(page).to have_text("Before you start")
    page.click_link("Start now")

    expect(page).to have_text("Have you agreed a start date of")
    page.choose("Yes", visible: :all)
    page.click_button("Continue")

    expect(page).to have_text("Have you already chosen an NPQ and provider?")
    page.choose("Yes, I have chosen my NPQ and provider")
    page.click_button("Continue")

    expect(page.current_path).to eql("/registration/teacher-catchment")
    page.choose("Another country")
    page.select("China")
    page.click_button("Continue")

    expect(page.current_path).to eql("/registration/work-in-school")
    page.choose("Yes")
    page.click_button("Continue")

    expect(page.current_path).to eql("/registration/teacher-reference-number")
    page.choose("Yes, I know my TRN")
    page.click_button("Continue")

    expect(page.current_path).to include("contact-details")
    expect(page).to have_text("Email address")
    page.fill_in "Email address", with: "user@example.com"
    page.click_button("Continue")

    expect(page).to have_text("Confirm your code")
    expect(page).to have_text("user@example.com")

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

    expect(page).to have_text("Check your details")
    page.fill_in "Teacher reference number (TRN)", with: "1234567"
    page.fill_in "Full name", with: "John Doe"
    page.fill_in "Day", with: "13"
    page.fill_in "Month", with: "12"
    page.fill_in "Year", with: "1980"
    page.fill_in "National Insurance number (optional)", with: "AB123456C"
    page.click_button("Continue")

    expect(page).to have_text("What are you applying for?")
    expect(page).not_to have_text("Additional Support Offer for new headteachers")
    page.choose("NPQ for Headship (NPQH)")
    page.click_button("Continue")

    expect(page).to have_text("How is your course being paid for?")
    page.choose "My employer is paying"
    page.click_button("Continue")

    expect(page).to have_text("Choose your provider")
    page.choose("Teach First")
    page.click_button("Continue")

    expect(page).to have_text("Sharing your NPQ information")
    page.check("Yes, I agree my information can be shared")
    page.click_button("Continue")

    check_answers_page = CheckAnswersPage.new

    expect(check_answers_page).to be_displayed
    expect(check_answers_page.summary_list["Where do you work?"].value).to eql("China")
    expect(check_answers_page.summary_list["Do you work in a school or college?"].value).to eql("Yes")
    expect(check_answers_page.summary_list["Full name"].value).to eql("John Doe")
    expect(check_answers_page.summary_list["TRN"].value).to eql("1234567")
    expect(check_answers_page.summary_list["Date of birth"].value).to eql("13 December 1980")
    expect(check_answers_page.summary_list["National Insurance number"].value).to eql("AB123456C")
    expect(check_answers_page.summary_list["Email"].value).to eql("user@example.com")
    expect(check_answers_page.summary_list["Course"].value).to eql("NPQ for Headship (NPQH)")
    expect(check_answers_page.summary_list["Lead provider"].value).to eql("Teach First")
    expect(check_answers_page.summary_list.key?("School or college")).to be_falsey

    allow(ApplicationSubmissionJob).to receive(:perform_later).with(anything)

    page.click_button("Submit")

    expect(page).to have_text("Your initial registration is complete")

    expect(User.count).to eql(1)

    user = User.last

    expect(user.email).to eql("user@example.com")
    expect(user.full_name).to eql("John Doe")
    expect(user.trn_verified).to be_truthy
    expect(user.trn_auto_verified).to be_truthy
    expect(user.date_of_birth).to eql(Date.new(1980, 12, 13))
    expect(user.national_insurance_number).to be_blank

    expect(user.applications.count).to eql(1)

    application = user.applications.first

    expect(application.course).to be_npqh
    expect(application.eligible_for_funding).to be_falsey
    expect(application.funding_choice).to eql("employer")
    expect(application.teacher_catchment).to eql("another")
    expect(application.teacher_catchment_country).to eql("China")

    visit "/account"

    expect(page).to have_text("Teach First")
    expect(page).to have_text("NPQ for Headship (NPQH)")

    visit "/registration/share-provider"

    expect(page).to have_content("Before you start")
  end
end
