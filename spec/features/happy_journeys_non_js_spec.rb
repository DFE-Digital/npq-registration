require "rails_helper"

RSpec.feature "Happy journeys", type: :feature do
  around do |example|
    Capybara.current_driver = :rack_test

    example.run

    Capybara.current_driver = Capybara.default_driver
  end

  def latest_application
    Application.order(created_at: :asc).last
  end

  def latest_application_user
    latest_application.user
  end

  def retrieve_latest_application_user_data
    latest_application_user.as_json(except: %i[id created_at updated_at])
  end

  def retrieve_latest_application_data
    latest_application.as_json(except: %i[id created_at updated_at user_id])
  end

  scenario "registration journey via using old name and not headship" do
    visit "/"
    expect(page).to have_text("Before you start")
    page.click_link("Start now")

    expect(page).to have_text("Have you already chosen an NPQ and provider?")
    page.choose("Yes")
    page.click_button("Continue")

    expect(page.current_path).to eql("/registration/teacher-catchment")
    page.choose("England")
    page.click_button("Continue")

    expect(page.current_path).to eql("/registration/work-in-school")
    page.choose("Yes")
    page.click_button("Continue")

    expect(page.current_path).to eql("/registration/teacher-reference-number")
    page.choose("I need a reminder")
    page.click_button("Continue")

    expect(page).to have_text("If you don’t know what your teacher reference number")
    page.click_link("Back")

    expect(page.current_path).to eql("/registration/teacher-reference-number")
    page.choose("I do not have a TRN")
    page.click_button("Continue")

    expect(page).to have_text("Get a Teacher Reference Number (TRN)")
    page.click_link("Back")

    expect(page.current_path).to eql("/registration/teacher-reference-number")
    page.choose("Yes")
    page.click_button("Continue")

    expect(page.current_path).to include("contact-details")
    expect(page).to have_text("What's your email address?")
    page.fill_in "What's your email address?", with: "user@example.com"
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
          nino: "AB123456C",
        },
      )
      .to_return(status: 200, body: participant_validator_response(trn: "12345"), headers: {})

    expect(page).to have_text("Check your details")
    page.fill_in "Teacher reference number (TRN)", with: "RP12/345"
    page.fill_in "Full name", with: "John Doe"
    page.fill_in "Day", with: "13"
    page.fill_in "Month", with: "12"
    page.fill_in "Year", with: "1980"
    page.fill_in "National Insurance number", with: "AB123456C"
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
    page.fill_in "Workplace location", with: "manchester"
    page.click_button("Continue")

    expect(page).to have_text("Choose your workplace")
    expect(page).to have_text("Choose from schools, trusts and 16 to 19 educational settings located in manchester")

    within ".npq-js-hidden" do
      page.fill_in "Enter the name of your workplace", with: "open"
    end
    page.click_button("Continue")

    expect(page).to have_text("Choose your workplace")
    page.choose "open manchester school"
    page.click_button("Continue")

    stub_request(:get, "https://ecf-app.gov.uk/api/v1/npq-funding/RP12%2F345?npq_course_identifier=npq-senior-leadership")
      .with(
        headers: {
          "Authorization" => "Bearer ECFAPPBEARERTOKEN",
        },
      )
      .to_return(
        status: 200,
        body: previously_funded_response(false),
        headers: {
          "Content-Type" => "application/vnd.api+json",
        },
      )

    expect(page).to have_text("What are you applying for?")
    page.choose("NPQ for Senior Leadership (NPQSL)")
    page.click_button("Continue")

    stub_request(:get, "https://ecf-app.gov.uk/api/v1/npq-funding/1234567?npq_course_identifier=npq-headship")
      .with(
        headers: {
          "Authorization" => "Bearer ECFAPPBEARERTOKEN",
        },
      )
      .to_return(
        status: 200,
        body: previously_funded_response(false),
        headers: {
          "Content-Type" => "application/vnd.api+json",
        },
      )

    expect(page).to have_text("If your provider accepts your application, you’ll qualify for DfE funding")
    page.click_button("Continue")

    expect(page).to have_text("Select your provider")
    page.choose("Teach First")
    page.click_button("Continue")

    expect(page).to have_text("Sharing your NPQ information")
    page.check("Yes, I agree my information can be shared")
    page.click_button("Continue")

    check_answers_page = CheckAnswersPage.new

    expect(check_answers_page).to be_displayed

    summary_data = check_answers_page.summary_list.rows.map { |summary_item|
      [summary_item.key, summary_item.value]
    }.to_h

    expect(summary_data).to eql(
      "Where do you work?" => "England",
      "Do you work in a school, academy trust, or 16 to 19 educational setting?" => "Yes",
      "Full name" => "John Doe",
      "TRN" => "RP12/345",
      "Date of birth" => "13 December 1980",
      "National Insurance number" => "AB123456C",
      "Email" => "user@example.com",
      "Course" => "NPQ for Senior Leadership (NPQSL)",
      "Workplace" => "open manchester school",
      "Lead provider" => "Teach First",
    )

    allow(ApplicationSubmissionJob).to receive(:perform_later).with(anything)

    page.click_button("Submit")

    expect(User.count).to eql(1)
    expect(Application.count).to eql(1)

    visit "/"
    visit "/registration/confirmation"

    expect(page.current_path).to eql("/")

    expect(retrieve_latest_application_user_data).to eq(
      "active_alert" => false,
      "admin" => false,
      "date_of_birth" => "1980-12-13",
      "ecf_id" => nil,
      "email" => "user@example.com",
      "full_name" => "John Doe",
      "national_insurance_number" => nil,
      "otp_expires_at" => nil,
      "otp_hash" => nil,
      "trn" => "0012345",
      "trn_auto_verified" => true,
      "trn_verified" => true,
    )
    expect(retrieve_latest_application_data).to eq(
      "cohort" => 2022,
      "course_id" => Course.find_by_code(code: :NPQSL).id,
      "ecf_id" => nil,
      "eligible_for_funding" => true,
      "employer_name" => nil,
      "employment_role" => nil,
      "funding_choice" => nil,
      "funding_eligiblity_status_code" => "funded",
      "headteacher_status" => nil,
      "kind_of_nursery" => nil,
      "lead_provider_id" => LeadProvider.find_by(name: "Teach First").id,
      "private_childcare_provider_urn" => nil,
      "school_urn" => "100000",
      "targeted_delivery_funding_eligibility" => true,
      "targeted_support_funding_eligibility" => false,
      "teacher_catchment" => "england",
      "teacher_catchment_country" => nil,
      "ukprn" => nil,
      "works_in_childcare" => false,
      "works_in_nursery" => false,
      "works_in_school" => true,
      "raw_application_data" => {
        "active_alert" => false,
        "can_share_choices" => "1",
        "chosen_provider" => "yes",
        "confirmed_email" => "user@example.com",
        "course_id" => Course.find_by_code(code: :NPQSL).id.to_s,
        "date_of_birth" => "1980-12-13",
        "email" => "user@example.com",
        "full_name" => "John Doe",
        "institution_identifier" => "School-100000",
        "institution_location" => "manchester",
        "institution_name" => "open",
        "lead_provider_id" => "9",
        "national_insurance_number" => "AB123456C",
        "teacher_catchment" => "england",
        "teacher_catchment_country" => nil,
        "trn" => "RP12/345",
        "trn_auto_verified" => true,
        "trn_knowledge" => "yes",
        "trn_verified" => true,
        "verified_trn" => "12345",
        "works_in_school" => "yes",
      },
    )
  end

  scenario "registration journey via using same name" do
    visit "/"
    expect(page).to have_text("Before you start")
    page.click_link("Start now")

    expect(page).to have_text("Have you already chosen an NPQ and provider?")
    page.choose("Yes")
    page.click_button("Continue")

    expect(page.current_path).to eql("/registration/teacher-catchment")
    page.choose("England")
    page.click_button("Continue")

    expect(page.current_path).to eql("/registration/work-in-school")
    page.choose("Yes")
    page.click_button("Continue")

    expect(page.current_path).to eql("/registration/teacher-reference-number")
    page.choose("Yes")
    page.click_button("Continue")

    expect(page.current_path).to include("contact-details")
    expect(page).to have_text("What's your email address?")
    page.fill_in "What's your email address?", with: "user@example.com"
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
    page.fill_in "National Insurance number", with: "AB123456C"
    page.click_button("Continue")

    School.create!(urn: 100_000, name: "open manchester school", address_1: "street 1", town: "manchester", establishment_status_code: "1")
    School.create!(urn: 100_001, name: "closed manchester school", address_1: "street 2", town: "manchester", establishment_status_code: "2")
    School.create!(urn: 100_002, name: "open newcastle school", address_1: "street 3", town: "newcastle", establishment_status_code: "1")

    expect(page).to have_text("Where is your school, college or academy trust?")
    page.fill_in "Workplace location", with: "manchester"
    page.click_button("Continue")

    expect(page).to have_text("Choose your workplace")
    expect(page).to have_text("Choose from schools, trusts and 16 to 19 educational settings located in manchester")
    within ".npq-js-hidden" do
      page.fill_in "Enter the name of your workplace", with: "open"
    end
    page.click_button("Continue")

    expect(page).to have_text("Choose your workplace")
    page.choose "open manchester school"
    page.click_button("Continue")

    stub_request(:get, "https://ecf-app.gov.uk/api/v1/npq-funding/1234567?npq_course_identifier=npq-headship")
      .with(
        headers: {
          "Authorization" => "Bearer ECFAPPBEARERTOKEN",
        },
      )
      .to_return(
        status: 200,
        body: previously_funded_response(false),
        headers: {
          "Content-Type" => "application/vnd.api+json",
        },
      )

    expect(page).to have_text("What are you applying for?")
    page.choose("NPQ for Headship (NPQH)")
    page.click_button("Continue")

    expect(page).to have_text("DfE scholarship funding is not available")
    expect(page).to have_text("To be eligible for scholarship funding for")
    expect(page).to have_text("state-funded schools")
    expect(page).to have_text("state-funded 16 to 19 organisations")
    expect(page).to have_text("independent special schools")
    expect(page).to have_text("virtual schools")
    expect(page).to have_text("hospital schools")
    expect(page).to have_text("young offenders institutions")
    page.click_link("Continue")

    expect(page).to have_text("How is your course being paid for?")
    page.choose "My trust is paying"
    page.click_button("Continue")

    expect(page).to have_text("Select your provider")
    page.choose("Teach First")
    page.click_button("Continue")

    expect(page).to have_text("Sharing your NPQ information")
    page.check("Yes, I agree my information can be shared")
    page.click_button("Continue")

    check_answers_page = CheckAnswersPage.new

    expect(check_answers_page).to be_displayed

    summary_data = check_answers_page.summary_list.rows.map { |summary_item|
      [summary_item.key, summary_item.value]
    }.to_h

    expect(summary_data).to eql(
      "Where do you work?" => "England",
      "Do you work in a school, academy trust, or 16 to 19 educational setting?" => "Yes",
      "Full name" => "John Doe",
      "TRN" => "1234567",
      "Date of birth" => "13 December 1980",
      "National Insurance number" => "AB123456C",
      "Email" => "user@example.com",
      "Course" => "NPQ for Headship (NPQH)",
      "Lead provider" => "Teach First",
      "Workplace" => "open manchester school",
      "How is your NPQ being paid for?" => "My trust is paying",
    )

    allow(ApplicationSubmissionJob).to receive(:perform_later).with(anything)

    page.click_button("Submit")

    expect(page).to have_text("Your initial registration is complete")
    expect(page).to have_text("The Early Headship Coaching Offer is a package of structured face-to-face support for new headteachers.")

    expect(User.count).to eql(1)

    user = User.last
    expect(user.applications.count).to eql(1)

    visit "/account"

    expect(page).to have_text("Teach First")
    expect(page).to have_text("NPQ for Headship (NPQH)")

    visit "/registration/check-answers"

    expect(page.current_path).to eql("/")

    expect(retrieve_latest_application_user_data).to eq(
      "active_alert" => false,
      "admin" => false,
      "date_of_birth" => "1980-12-13",
      "ecf_id" => nil,
      "email" => "user@example.com",
      "full_name" => "John Doe",
      "national_insurance_number" => nil,
      "otp_expires_at" => nil,
      "otp_hash" => nil,
      "trn" => "1234567",
      "trn_auto_verified" => true,
      "trn_verified" => true,
    )
    expect(retrieve_latest_application_data).to eq(
      "cohort" => 2022,
      "course_id" => Course.find_by_code(code: :NPQH).id,
      "ecf_id" => nil,
      "eligible_for_funding" => false,
      "employer_name" => nil,
      "employment_role" => nil,
      "funding_choice" => "trust",
      "funding_eligiblity_status_code" => "ineligible_establishment_type",
      "headteacher_status" => nil,
      "kind_of_nursery" => nil,
      "lead_provider_id" => LeadProvider.find_by(name: "Teach First").id,
      "private_childcare_provider_urn" => nil,
      "school_urn" => "100000",
      "targeted_delivery_funding_eligibility" => false,
      "targeted_support_funding_eligibility" => false,
      "teacher_catchment" => "england",
      "teacher_catchment_country" => nil,
      "ukprn" => nil,
      "works_in_childcare" => false,
      "works_in_nursery" => false,
      "works_in_school" => true,
      "raw_application_data" => {
        "active_alert" => false,
        "can_share_choices" => "1",
        "chosen_provider" => "yes",
        "confirmed_email" => "user@example.com",
        "course_id" => Course.find_by_code(code: :NPQH).id.to_s,
        "date_of_birth" => "1980-12-13",
        "email" => "user@example.com",
        "full_name" => "John Doe",
        "funding" => "trust",
        "institution_identifier" => "School-100000",
        "institution_location" => "manchester",
        "institution_name" => "open",
        "lead_provider_id" => "9",
        "national_insurance_number" => "AB123456C",
        "teacher_catchment" => "england",
        "teacher_catchment_country" => nil,
        "trn" => "1234567",
        "trn_auto_verified" => true,
        "trn_knowledge" => "yes",
        "trn_verified" => true,
        "verified_trn" => "1234567",
        "works_in_school" => "yes",
      },
    )
  end

  scenario "other funded EHCO registration journey" do
    visit "/"
    expect(page).to have_text("Before you start")
    page.click_link("Start now")

    expect(page).to have_text("Have you already chosen an NPQ and provider?")
    page.choose("Yes")
    page.click_button("Continue")

    expect(page.current_path).to eql("/registration/teacher-catchment")
    page.choose("England")
    page.click_button("Continue")

    expect(page.current_path).to eql("/registration/work-in-school")
    page.choose("Yes")
    page.click_button("Continue")

    expect(page.current_path).to eql("/registration/teacher-reference-number")
    page.choose("Yes")
    page.click_button("Continue")

    expect(page.current_path).to include("contact-details")
    expect(page).to have_text("What's your email address?")
    page.fill_in "What's your email address?", with: "user@example.com"
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
    page.fill_in "National Insurance number", with: "AB123456C"
    page.click_button("Continue")

    School.create!(urn: 100_000, name: "open manchester school", address_1: "street 1", town: "manchester", establishment_status_code: "1")
    School.create!(urn: 100_001, name: "closed manchester school", address_1: "street 2", town: "manchester", establishment_status_code: "2")
    School.create!(urn: 100_002, name: "open newcastle school", address_1: "street 3", town: "newcastle", establishment_status_code: "1")

    expect(page).to have_text("Where is your school, college or academy trust?")
    page.fill_in "Workplace location", with: "manchester"
    page.click_button("Continue")

    expect(page).to have_text("Choose your workplace")
    expect(page).to have_text("Choose from schools, trusts and 16 to 19 educational settings located in manchester")
    within ".npq-js-hidden" do
      page.fill_in "Enter the name of your workplace", with: "open"
    end
    page.click_button("Continue")

    expect(page).to have_text("Choose your workplace")
    page.choose "open manchester school"
    page.click_button("Continue")

    expect(page).to have_text("What are you applying for?")
    page.choose("Early Headship Coaching Offer")
    page.click_button("Continue")

    expect(page).to have_selector "h1", text: "Early Headship Coaching Offer"
    page.click_link("Continue")

    expect(page).to have_selector "h1", text: "Are you studying for, or have you completed an NPQ for Headship (NPQH)?"
    page.choose "None of the above"
    page.click_button("Continue")

    expect(page).to have_selector "h1", text: "You cannot register for the Early Headship Coaching Offer"
    page.click_link("Back")

    expect(page).to have_selector "h1", text: "Are you studying for, or have you completed an NPQ for Headship (NPQH)?"
    page.choose "I have completed an NPQH"
    page.click_button("Continue")

    expect(page).to have_selector "h1", text: "Are you a headteacher?"
    page.choose "No"
    page.click_button("Continue")

    stub_request(:get, "https://ecf-app.gov.uk/api/v1/npq-funding/1234567?npq_course_identifier=npq-early-headship-coaching-offer")
      .with(
        headers: {
          "Authorization" => "Bearer ECFAPPBEARERTOKEN",
        },
      )
      .to_return(
        status: 200,
        body: previously_funded_response(false),
        headers: {
          "Content-Type" => "application/vnd.api+json",
        },
      )

    expect(page).to have_selector "h1", text: "DfE scholarship funding is not available"
    page.click_button("Continue")

    expect(page).to have_selector "h1", text: "How is the Early Headship Coaching Offer being paid for?"
    page.choose "I am paying"
    page.click_button("Continue")

    expect(page).to have_text("Select your provider")
    page.choose("Teach First")
    page.click_button("Continue")

    expect(page).to have_text("Sharing your NPQ information")
    page.check("Yes, I agree my information can be shared")
    page.click_button("Continue")

    check_answers_page = CheckAnswersPage.new

    expect(check_answers_page).to be_displayed

    summary_data = check_answers_page.summary_list.rows.map { |summary_item|
      [summary_item.key, summary_item.value]
    }.to_h

    expect(summary_data).to eql(
      "Where do you work?" => "England",
      "Do you work in a school, academy trust, or 16 to 19 educational setting?" => "Yes",
      "Full name" => "John Doe",
      "TRN" => "1234567",
      "Date of birth" => "13 December 1980",
      "National Insurance number" => "AB123456C",
      "Email" => "user@example.com",
      "Course" => "Early Headship Coaching Offer",
      "Lead provider" => "Teach First",
      "Workplace" => "open manchester school",
      "Are you a headteacher?" => "No",
      "Have you completed an NPQH?" => "I have completed an NPQH",
      "How is your EHCO being paid for?" => "I am paying",
    )

    allow(ApplicationSubmissionJob).to receive(:perform_later).with(anything)

    page.click_button("Submit")

    expect(page).to have_text("Your initial registration is complete")
    expect(page).to_not have_text("The Early Headship Coaching Offer is a package of structured face-to-face support for new headteachers.")

    expect(User.count).to eql(1)

    user = User.last

    expect(user.applications.count).to eql(1)

    visit "/account"

    expect(page).to have_text("Teach First")
    expect(page).to have_text("Early Headship Coaching Offer")

    visit "/registration/check-answers"

    expect(page.current_path).to eql("/")

    expect(retrieve_latest_application_user_data).to eq(
      "active_alert" => false,
      "admin" => false,
      "date_of_birth" => "1980-12-13",
      "ecf_id" => nil,
      "email" => "user@example.com",
      "full_name" => "John Doe",
      "national_insurance_number" => nil,
      "otp_expires_at" => nil,
      "otp_hash" => nil,
      "trn" => "1234567",
      "trn_auto_verified" => true,
      "trn_verified" => true,
    )
    expect(retrieve_latest_application_data).to eq(
      "cohort" => 2022,
      "course_id" => Course.find_by_code(code: :EHCO).id,
      "ecf_id" => nil,
      "eligible_for_funding" => false,
      "employer_name" => nil,
      "employment_role" => nil,
      "funding_choice" => "self",
      "funding_eligiblity_status_code" => "ineligible_establishment_type",
      "headteacher_status" => "no",
      "kind_of_nursery" => nil,
      "lead_provider_id" => LeadProvider.find_by(name: "Teach First").id,
      "private_childcare_provider_urn" => nil,
      "school_urn" => "100000",
      "targeted_delivery_funding_eligibility" => false,
      "targeted_support_funding_eligibility" => false,
      "teacher_catchment" => "england",
      "teacher_catchment_country" => nil,
      "ukprn" => nil,
      "works_in_childcare" => false,
      "works_in_nursery" => false,
      "works_in_school" => true,
      "raw_application_data" => {
        "active_alert" => false,
        "aso_funding_choice" => "self",
        "aso_headteacher" => "no",
        "can_share_choices" => "1",
        "chosen_provider" => "yes",
        "confirmed_email" => "user@example.com",
        "course_id" => Course.find_by_code(code: :EHCO).id.to_s,
        "date_of_birth" => "1980-12-13",
        "email" => "user@example.com",
        "full_name" => "John Doe",
        "institution_identifier" => "School-100000",
        "institution_location" => "manchester",
        "institution_name" => "open",
        "lead_provider_id" => LeadProvider.find_by(name: "Teach First").id.to_s,
        "national_insurance_number" => "AB123456C",
        "npqh_status" => "completed_npqh",
        "teacher_catchment" => "england",
        "teacher_catchment_country" => nil,
        "trn" => "1234567",
        "trn_auto_verified" => true,
        "trn_knowledge" => "yes",
        "trn_verified" => true,
        "verified_trn" => "1234567",
        "works_in_school" => "yes",
      },
    )
  end

  scenario "funded EHCO registration journey" do
    visit "/"
    expect(page).to have_text("Before you start")
    page.click_link("Start now")

    expect(page).to have_text("Have you already chosen an NPQ and provider?")
    page.choose("Yes")
    page.click_button("Continue")

    expect(page.current_path).to eql("/registration/teacher-catchment")
    page.choose("England")
    page.click_button("Continue")

    expect(page.current_path).to eql("/registration/work-in-school")
    page.choose("Yes")
    page.click_button("Continue")

    expect(page.current_path).to eql("/registration/teacher-reference-number")
    page.choose("Yes")
    page.click_button("Continue")

    expect(page.current_path).to include("contact-details")
    expect(page).to have_text("What's your email address?")
    page.fill_in "What's your email address?", with: "user@example.com"
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
    page.fill_in "National Insurance number", with: "AB123456C"
    page.click_button("Continue")

    School.create!(urn: 100_000, name: "open manchester school", address_1: "street 1", town: "manchester", establishment_status_code: "1", establishment_type_code: "1")
    School.create!(urn: 100_001, name: "closed manchester school", address_1: "street 2", town: "manchester", establishment_status_code: "2")
    School.create!(urn: 100_002, name: "open newcastle school", address_1: "street 3", town: "newcastle", establishment_status_code: "1")

    expect(page).to have_text("Where is your school, college or academy trust?")
    page.fill_in "Workplace location", with: "manchester"
    page.click_button("Continue")

    expect(page).to have_text("Choose your workplace")
    expect(page).to have_text("Choose from schools, trusts and 16 to 19 educational settings located in manchester")
    within ".npq-js-hidden" do
      page.fill_in "Enter the name of your workplace", with: "open"
    end
    page.click_button("Continue")

    expect(page).to have_text("Choose your workplace")
    page.choose "open manchester school"
    page.click_button("Continue")

    expect(page).to have_text("What are you applying for?")
    page.choose("Early Headship Coaching Offer")
    page.click_button("Continue")

    expect(page).to have_selector "h1", text: "Early Headship Coaching Offer"
    page.click_link("Continue")

    expect(page).to have_selector "h1", text: "Are you studying for, or have you completed an NPQ for Headship (NPQH)?"
    page.choose "None of the above"
    page.click_button("Continue")

    expect(page).to have_selector "h1", text: "You cannot register for the Early Headship Coaching Offer"
    page.click_link("Back")

    expect(page).to have_selector "h1", text: "Are you studying for, or have you completed an NPQ for Headship (NPQH)?"
    page.choose "I have completed an NPQH"
    page.click_button("Continue")

    expect(page).to have_selector "h1", text: "Are you a headteacher?"
    page.choose "Yes"
    page.click_button("Continue")

    stub_request(:get, "https://ecf-app.gov.uk/api/v1/npq-funding/1234567?npq_course_identifier=npq-early-headship-coaching-offer")
      .with(
        headers: {
          "Authorization" => "Bearer ECFAPPBEARERTOKEN",
        },
      )
      .to_return(
        status: 200,
        body: previously_funded_response(false),
        headers: {
          "Content-Type" => "application/vnd.api+json",
        },
      )

    expect(page).to have_selector "h1", text: "Are you in your first 5 years of a headship?"
    page.choose "Yes"
    page.click_button("Continue")

    expect(page).to have_selector "h1", text: "If your provider accepts your application, you’ll qualify for DfE scholarship funding"
    page.click_button("Continue")

    expect(page).to have_text("Select your provider")
    page.choose("Teach First")
    page.click_button("Continue")

    expect(page).to have_text("Sharing your NPQ information")
    page.check("Yes, I agree my information can be shared")
    page.click_button("Continue")

    check_answers_page = CheckAnswersPage.new

    expect(check_answers_page).to be_displayed

    summary_data = check_answers_page.summary_list.rows.map { |summary_item|
      [summary_item.key, summary_item.value]
    }.to_h

    expect(summary_data).to eql(
      "Where do you work?" => "England",
      "Do you work in a school, academy trust, or 16 to 19 educational setting?" => "Yes",
      "Full name" => "John Doe",
      "TRN" => "1234567",
      "Date of birth" => "13 December 1980",
      "National Insurance number" => "AB123456C",
      "Email" => "user@example.com",
      "Course" => "Early Headship Coaching Offer",
      "Lead provider" => "Teach First",
      "Workplace" => "open manchester school",
      "Are you a headteacher?" => "Yes",
      "Are you in your first 5 years of a headship?" => "Yes",
      "Have you completed an NPQH?" => "I have completed an NPQH",
    )

    allow(ApplicationSubmissionJob).to receive(:perform_later).with(anything)

    page.click_button("Submit")

    expect(page).to have_text("Your initial registration is complete")
    expect(page).to_not have_text("The Early Headship Coaching Offer is a package of structured face-to-face support for new headteachers.")

    expect(User.count).to eql(1)

    user = User.last

    expect(user.applications.count).to eql(1)

    visit "/account"

    expect(page).to have_text("Teach First")
    expect(page).to have_text("Early Headship Coaching Offer")

    visit "/registration/check-answers"

    expect(page.current_path).to eql("/")

    expect(retrieve_latest_application_user_data).to eq(
      "active_alert" => false,
      "admin" => false,
      "date_of_birth" => "1980-12-13",
      "ecf_id" => nil,
      "email" => "user@example.com",
      "full_name" => "John Doe",
      "national_insurance_number" => nil,
      "otp_expires_at" => nil,
      "otp_hash" => nil,
      "trn" => "1234567",
      "trn_auto_verified" => true,
      "trn_verified" => true,
    )
    expect(retrieve_latest_application_data).to eq(
      "cohort" => 2022,
      "course_id" => Course.find_by_code(code: :EHCO).id,
      "ecf_id" => nil,
      "eligible_for_funding" => true,
      "employer_name" => nil,
      "employment_role" => nil,
      "funding_choice" => nil,
      "funding_eligiblity_status_code" => "funded",
      "headteacher_status" => "yes_in_first_five_years",
      "kind_of_nursery" => nil,
      "lead_provider_id" => LeadProvider.find_by(name: "Teach First").id,
      "private_childcare_provider_urn" => nil,
      "school_urn" => "100000",
      "targeted_delivery_funding_eligibility" => false,
      "targeted_support_funding_eligibility" => false,
      "teacher_catchment" => "england",
      "teacher_catchment_country" => nil,
      "ukprn" => nil,
      "works_in_childcare" => false,
      "works_in_nursery" => false,
      "works_in_school" => true,
      "raw_application_data" => {
        "active_alert" => false,
        "aso_headteacher" => "yes",
        "aso_new_headteacher" => "yes",
        "can_share_choices" => "1",
        "chosen_provider" => "yes",
        "confirmed_email" => "user@example.com",
        "course_id" => Course.find_by_code(code: :EHCO).id.to_s,
        "date_of_birth" => "1980-12-13",
        "email" => "user@example.com",
        "full_name" => "John Doe",
        "institution_identifier" => "School-100000",
        "institution_location" => "manchester",
        "institution_name" => "open",
        "lead_provider_id" => "9",
        "national_insurance_number" => "AB123456C",
        "npqh_status" => "completed_npqh",
        "teacher_catchment" => "england",
        "teacher_catchment_country" => nil,
        "trn" => "1234567",
        "trn_auto_verified" => true,
        "trn_knowledge" => "yes",
        "trn_verified" => true,
        "verified_trn" => "1234567",
        "works_in_school" => "yes",
      },
    )
  end

  scenario "international teacher NPQH journey" do
    visit "/"
    expect(page).to have_text("Before you start")
    page.click_link("Start now")

    expect(page).to have_text("Have you already chosen an NPQ and provider?")
    page.choose("Yes")
    page.click_button("Continue")

    expect(page.current_path).to eql("/registration/teacher-catchment")
    page.choose("Another country")
    page.select("China")
    page.click_button("Continue")

    expect(page.current_path).to eql("/registration/work-in-school")
    page.choose("Yes")
    page.click_button("Continue")

    expect(page.current_path).to eql("/registration/teacher-reference-number")
    page.choose("Yes")
    page.click_button("Continue")

    expect(page.current_path).to include("contact-details")
    expect(page).to have_text("What's your email address?")
    page.fill_in "What's your email address?", with: "user@example.com"
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

    expect(page).to have_text("DfE scholarship funding is not available")
    expect(page).to have_text("To be eligible for scholarship funding for")
    expect(page).to have_text("state-funded schools")
    expect(page).to have_text("state-funded 16 to 19 organisations")
    expect(page).to have_text("independent special schools")
    expect(page).to have_text("virtual schools")
    expect(page).to have_text("hospital schools")
    expect(page).to have_text("young offenders institutions")
    page.click_link("Continue")

    expect(page).to have_text("How is your course being paid for?")
    page.choose "My workplace is covering the cost"
    page.click_button("Continue")

    expect(page).to have_text("Select your provider")
    page.choose("Teach First")
    page.click_button("Continue")

    expect(page).to have_text("Sharing your NPQ information")
    page.check("Yes, I agree my information can be shared")
    page.click_button("Continue")

    check_answers_page = CheckAnswersPage.new

    expect(check_answers_page).to be_displayed

    summary_data = check_answers_page.summary_list.rows.map { |summary_item|
      [summary_item.key, summary_item.value]
    }.to_h

    expect(summary_data).to eql(
      "Where do you work?" => "China",
      "Do you work in a school, academy trust, or 16 to 19 educational setting?" => "Yes",
      "Full name" => "John Doe",
      "TRN" => "1234567",
      "Date of birth" => "13 December 1980",
      "National Insurance number" => "AB123456C",
      "Email" => "user@example.com",
      "Course" => "NPQ for Headship (NPQH)",
      "Lead provider" => "Teach First",
      "How is your NPQ being paid for?" => "My workplace is covering the cost",
    )

    allow(ApplicationSubmissionJob).to receive(:perform_later).with(anything)

    page.click_button("Submit")

    expect(page).to have_text("Your initial registration is complete")
    expect(page).to have_text("The Early Headship Coaching Offer is a package of structured face-to-face support for new headteachers.")

    expect(User.count).to eql(1)

    user = User.last

    expect(user.applications.count).to eql(1)

    visit "/account"

    expect(page).to have_text("Teach First")
    expect(page).to have_text("NPQ for Headship (NPQH)")

    visit "/registration/share-provider"

    expect(page).to have_content("Before you start")

    expect(retrieve_latest_application_user_data).to eq(
      "active_alert" => false,
      "admin" => false,
      "date_of_birth" => "1980-12-13",
      "ecf_id" => nil,
      "email" => "user@example.com",
      "full_name" => "John Doe",
      "national_insurance_number" => nil,
      "otp_expires_at" => nil,
      "otp_hash" => nil,
      "trn" => "1234567",
      "trn_auto_verified" => true,
      "trn_verified" => true,
    )

    expect(retrieve_latest_application_user_data).to eq(
      "active_alert" => false,
      "admin" => false,
      "date_of_birth" => "1980-12-13",
      "ecf_id" => nil,
      "email" => "user@example.com",
      "full_name" => "John Doe",
      "national_insurance_number" => nil,
      "otp_expires_at" => nil,
      "otp_hash" => nil,
      "trn" => "1234567",
      "trn_auto_verified" => true,
      "trn_verified" => true,
    )
    expect(retrieve_latest_application_data).to eq(
      "cohort" => 2022,
      "course_id" => Course.find_by_code(code: :NPQH).id,
      "ecf_id" => nil,
      "eligible_for_funding" => false,
      "employer_name" => nil,
      "employment_role" => nil,
      "funding_choice" => "school",
      "funding_eligiblity_status_code" => "no_institution",
      "headteacher_status" => nil,
      "kind_of_nursery" => nil,
      "lead_provider_id" => LeadProvider.find_by(name: "Teach First").id,
      "private_childcare_provider_urn" => nil,
      "school_urn" => nil,
      "targeted_delivery_funding_eligibility" => false,
      "targeted_support_funding_eligibility" => false,
      "teacher_catchment" => "another",
      "teacher_catchment_country" => "China",
      "ukprn" => nil,
      "works_in_childcare" => false,
      "works_in_nursery" => false,
      "works_in_school" => true,
      "raw_application_data" => {
        "active_alert" => false,
        "can_share_choices" => "1",
        "chosen_provider" => "yes",
        "confirmed_email" => "user@example.com",
        "course_id" => Course.find_by_code(code: :NPQH).id.to_s,
        "date_of_birth" => "1980-12-13",
        "email" => "user@example.com",
        "full_name" => "John Doe",
        "funding" => "school",
        "lead_provider_id" => "9",
        "national_insurance_number" => "AB123456C",
        "teacher_catchment" => "another",
        "teacher_catchment_country" => "China",
        "trn" => "1234567",
        "trn_auto_verified" => true,
        "trn_knowledge" => "yes",
        "trn_verified" => true,
        "verified_trn" => "1234567",
        "works_in_school" => "yes",
      },
    )
  end
end
