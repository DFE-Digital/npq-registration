require "rails_helper"

RSpec.feature "Sad journeys", type: :feature do
  def latest_application
    Application.order(created_at: :asc).last
  end

  def latest_application_user
    latest_application&.user
  end

  def retrieve_latest_application_user_data
    latest_application_user&.as_json(except: %i[id created_at updated_at])
  end

  def retrieve_latest_application_data
    latest_application&.as_json(except: %i[id created_at updated_at user_id])
  end

  before do
    # Make sure all the tests are checking this data
    expect(self).to receive(:retrieve_latest_application_user_data).and_call_original
    expect(self).to receive(:retrieve_latest_application_data).and_call_original
  end

  scenario "DQT mismatch" do
    visit "/"
    expect(page).to have_text("Before you start")
    page.click_link("Start now")

    expect(page).to be_axe_clean
    expect(page).to have_text("Have you already chosen an NPQ and provider?")
    page.choose("Yes", visible: :all)
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
    expect(page).to have_text("What's your email address?")
    page.fill_in "What's your email address?", with: "user@example.com"
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
    page.fill_in "National Insurance number", with: "AB123456C"
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
    page.fill_in "Workplace location", with: "manchester"
    page.click_button("Continue")

    expect(page).to be_axe_clean
    expect(page).to have_text("Choose your workplace")
    expect(page).to have_text("Choose from schools, trusts and 16 to 19 educational settings located in manchester")
    within ".npq-js-reveal" do
      page.fill_in "Enter the name of your workplace", with: "open"
    end

    expect(page).to have_content("open manchester school")
    page.find("#school-picker__option--0").click
    page.click_button("Continue")

    stub_request(:get, "https://ecf-app.gov.uk/api/v1/npq-funding/1234567?npq_course_identifier=npq-senior-leadership")
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

    expect(page).to be_axe_clean
    expect(page).to have_text("What are you applying for?")
    page.choose("NPQ for Senior Leadership (NPQSL)", visible: :all)
    page.click_button("Continue")

    expect(page).to be_axe_clean
    expect(page).to have_text("DfE scholarship funding is not available")
    expect(page).to have_text("To be eligible for scholarship funding for")
    expect(page).to have_text("state-funded schools")
    expect(page).to have_text("state-funded 16 to 19 organisations")
    expect(page).to have_text("independent special schools")
    expect(page).to have_text("virtual schools")
    expect(page).to have_text("hospital schools")
    expect(page).to have_text("young offenders institutions")
    page.click_link("Continue")

    expect(page).to be_axe_clean
    expect(page).to have_text("How is your course being paid for?")
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

    summary_data = check_answers_page.summary_list.rows.map { |summary_item|
      [summary_item.key, summary_item.value]
    }.to_h

    expect(summary_data).to eql(
      "Full name" => "John Doeeeeee",
      "TRN" => "1234567",
      "Date of birth" => "13 December 1980",
      "National Insurance number" => "AB123456C",
      "Email" => "user@example.com",
      "Course" => "NPQ for Senior Leadership (NPQSL)",
      "Lead provider" => "Teach First",
      "Workplace" => "open manchester school",
      "How is your NPQ being paid for?" => "My trust is paying",
      "Do you work in a school, academy trust, or 16 to 19 educational setting?" => "Yes",
      "Where do you work?" => "England",
    )

    allow(ApplicationSubmissionJob).to receive(:perform_later).with(anything)

    page.click_button("Submit")

    expect(retrieve_latest_application_user_data).to eq(
      "active_alert" => nil,
      "admin" => false,
      "date_of_birth" => "1980-12-13",
      "ecf_id" => nil,
      "email" => "user@example.com",
      "full_name" => "John Doeeeeee",
      "national_insurance_number" => "AB123456C",
      "otp_expires_at" => nil,
      "otp_hash" => nil,
      "trn" => "1234567",
      "trn_auto_verified" => false,
      "trn_verified" => false,
    )
    expect(retrieve_latest_application_data).to eq(
      "cohort" => 2022,
      "course_id" => Course.find_by_code(code: :NPQSL).id,
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
        "active_alert" => nil,
        "can_share_choices" => "1",
        "chosen_provider" => "yes",
        "confirmed_email" => "user@example.com",
        "course_id" => Course.find_by_code(code: :NPQSL).id.to_s,
        "date_of_birth" => "1980-12-13",
        "email" => "user@example.com",
        "full_name" => "John Doeeeeee",
        "funding" => "trust",
        "institution_identifier" => "School-100000",
        "institution_location" => "manchester",
        "institution_name" => "",
        "lead_provider_id" => "9",
        "national_insurance_number" => "AB123456C",
        "teacher_catchment" => "england",
        "teacher_catchment_country" => nil,
        "trn" => "1234567",
        "trn_auto_verified" => nil,
        "trn_knowledge" => "yes",
        "trn_verified" => false,
        "verified_trn" => nil,
        "works_in_school" => "yes",
      },
    )
  end

  scenario "school not in england" do
    visit "/"
    expect(page).to have_text("Before you start")
    page.click_link("Start now")

    expect(page).to be_axe_clean
    expect(page).to have_text("Have you already chosen an NPQ and provider?")
    page.choose("Yes", visible: :all)
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
    expect(page).to have_text("What's your email address?")
    page.fill_in "What's your email address?", with: "user@example.com"
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
    page.fill_in "National Insurance number", with: "AB123456C"
    page.click_button("Continue")

    School.create!(urn: 100_000, name: "open welsh school", county: "Wrexham", establishment_status_code: "1", establishment_type_code: "30")

    expect(page).to be_axe_clean
    expect(page).to have_text("Where is your school, college or academy trust?")
    page.fill_in "Workplace location", with: "wrexham"
    page.click_button("Continue")

    expect(page).to be_axe_clean
    expect(page).to have_text("Choose your workplace")
    within ".npq-js-reveal" do
      page.fill_in "Enter the name of your workplace", with: "open"
    end

    expect(page).to have_content("open welsh school")
    page.find("#school-picker__option--0").click
    page.click_button("Continue")

    expect(page).to be_axe_clean
    expect(page).to have_text("School or college must be in England")
    page.click_link("Back")

    expect(page).to be_axe_clean
    expect(page).to have_text("Choose your workplace")

    expect(retrieve_latest_application_user_data).to eq(nil)
    expect(retrieve_latest_application_data).to eq(nil)
  end

  scenario "Not chosen DQT or provider" do
    visit "/"
    expect(page).to have_text("Before you start")
    page.click_link("Start now")

    expect(page).to be_axe_clean
    expect(page).to have_text("Have you already chosen an NPQ and provider?")
    page.choose("No", visible: :all)
    page.click_button("Continue")

    expect(page).to be_axe_clean
    expect(page).to have_text("Choosing an NPQ and Provider")

    expect(retrieve_latest_application_user_data).to eq(nil)
    expect(retrieve_latest_application_data).to eq(nil)
  end

  scenario "works in childcare but not in england" do
    visit "/"
    expect(page).to have_text("Before you start")
    page.click_link("Start now")

    expect(page).to be_axe_clean
    expect(page).to have_text("Have you already chosen an NPQ and provider?")
    page.choose("Yes", visible: :all)
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
    expect(page).to have_text("What's your email address?")
    page.fill_in "What's your email address?", with: "user@example.com"
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

    expect(page).to have_text("DfE scholarship funding is not available")
    expect(page).to have_text("To be eligible for scholarship funding for")
    expect(page).to have_text("Work in England")
    expect(page).to have_text("Be registered with Ofsted on the Early Years Register or the Childcare Register, or be registered with a Childminder Agency (CMA)")
    page.click_link("Continue")

    expect(page).to be_axe_clean
    expect(page).to have_text("How is your course being paid for?")
    page.choose "My workplace is covering the cost", visible: :all
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

    summary_data = check_answers_page.summary_list.rows.map { |summary_item|
      [summary_item.key, summary_item.value]
    }.to_h

    expect(summary_data).to eql(
      "Full name" => "John Doe",
      "TRN" => "1234567",
      "Date of birth" => "13 December 1980",
      "Email" => "user@example.com",
      "Course" => "NPQ for Senior Leadership (NPQSL)",
      "How is your NPQ being paid for?" => "My workplace is covering the cost",
      "Do you work in a school, academy trust, or 16 to 19 educational setting?" => "No",
      "Do you work in early years or childcare?" => "Yes",
      "Lead provider" => "Teach First",
      "Where do you work?" => "Scotland",
    )

    allow(ApplicationSubmissionJob).to receive(:perform_later).with(anything)

    page.click_button("Submit")

    expect(page).to be_axe_clean

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
      "course_id" => Course.find_by_code(code: :NPQSL).id,
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
      "teacher_catchment" => "scotland",
      "teacher_catchment_country" => nil,
      "ukprn" => nil,
      "works_in_childcare" => true,
      "works_in_nursery" => false,
      "works_in_school" => false,
      "raw_application_data" => {
        "active_alert" => false,
        "can_share_choices" => "1",
        "chosen_provider" => "yes",
        "confirmed_email" => "user@example.com",
        "course_id" => Course.find_by_code(code: :NPQSL).id.to_s,
        "date_of_birth" => "1980-12-13",
        "email" => "user@example.com",
        "full_name" => "John Doe",
        "funding" => "school",
        "lead_provider_id" => LeadProvider.find_by(name: "Teach First").id.to_s,
        "national_insurance_number" => "",
        "teacher_catchment" => "scotland",
        "teacher_catchment_country" => nil,
        "trn" => "1234567",
        "trn_auto_verified" => true,
        "trn_knowledge" => "yes",
        "trn_verified" => true,
        "verified_trn" => "1234567",
        "works_in_childcare" => "yes",
        "works_in_school" => "no",
      },
    )
  end

  scenario "applying for EHCO but not new headteacher" do
    visit "/"
    expect(page).to have_text("Before you start")
    page.click_link("Start now")

    expect(page).to be_axe_clean
    expect(page).to have_text("Have you already chosen an NPQ and provider?")
    page.choose("Yes", visible: :all)
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
    page.choose("No, I need help getting one", visible: :all)
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
    expect(page).to have_text("What's your email address?")
    page.fill_in "What's your email address?", with: "user@example.com"
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
    page.fill_in "National Insurance number", with: "AB123456C"
    page.click_button("Continue")

    School.create!(urn: 100_000, name: "open manchester school", address_1: "street 1", town: "manchester", establishment_status_code: "1")

    expect(page).to be_axe_clean
    expect(page).to have_text("Where is your school, college or academy trust?")
    page.fill_in "Workplace location", with: "manchester"
    page.click_button("Continue")

    expect(page).to be_axe_clean
    expect(page).to have_text("Choose your workplace")
    expect(page).to have_text("Choose from schools, trusts and 16 to 19 educational settings located in manchester")
    within ".npq-js-reveal" do
      page.fill_in "Enter the name of your workplace", with: "open"
    end

    expect(page).to have_content("open manchester school")
    page.find("#school-picker__option--0").click
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

    expect(page).to be_axe_clean
    expect(page).to have_text("What are you applying for?")
    page.choose("Early Headship Coaching Offer", visible: :all)
    page.click_button("Continue")

    expect(page).to be_axe_clean
    expect(page).to have_selector "h1", text: "Early Headship Coaching Offer"
    page.click_link("Continue")

    expect(page).to be_axe_clean
    page.text
    expect(page).to have_selector "h1", text: "Are you studying for, or have you completed an NPQ for Headship (NPQH)?"
    page.choose "None of the above", visible: :all
    page.click_button("Continue")

    expect(page).to be_axe_clean
    expect(page).to have_selector "h1", text: "You cannot register for the Early Headship Coaching Offer"
    page.click_link("Back")

    expect(page).to be_axe_clean
    expect(page).to have_selector "h1", text: "Are you studying for, or have you completed an NPQ for Headship (NPQH)?"
    page.choose "I have completed an NPQH", visible: :all
    page.click_button("Continue")

    expect(page).to be_axe_clean
    expect(page).to have_selector "h1", text: "Are you a headteacher?"
    page.choose "Yes", visible: :all
    page.click_button("Continue")

    expect(page).to be_axe_clean
    expect(page).to have_selector "h1", text: "Are you in your first 5 years of a headship?"
    page.choose "No", visible: :all
    page.click_button("Continue")

    expect(page).to have_selector "h1", text: "DfE scholarship funding is not available"
    page.click_button("Continue")

    expect(page).to have_selector "h1", text: "How is the Early Headship Coaching Offer being paid for?"
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

    expect(page).to be_axe_clean

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
      "Email" => "user@example.com",
      "Course" => "Early Headship Coaching Offer",
      "Lead provider" => "Teach First",
      "How is your EHCO being paid for?" => "I am paying",
      "Workplace" => "open manchester school",
      "Are you a headteacher?" => "Yes",
      "Are you in your first 5 years of a headship?" => "No",
      "Have you completed an NPQH?" => "I have completed an NPQH",
      "National Insurance number" => "AB123456C",
    )

    allow(ApplicationSubmissionJob).to receive(:perform_later).with(anything)

    page.click_button("Submit")

    expect(page).to be_axe_clean
    expect(page).to have_text("Your initial registration is complete")
    expect(page).to_not have_text("The Early Headship Coaching Offer is a package of structured face-to-face support for new headteachers.")

    expect(page).to be_axe_clean

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
      "cohort" => 2021,
      "course_id" => Course.find_by_code(code: :EHCO).id,
      "ecf_id" => nil,
      "eligible_for_funding" => false,
      "employer_name" => nil,
      "employment_role" => nil,
      "funding_choice" => "self",
      "funding_eligiblity_status_code" => "ineligible_establishment_type",
      "headteacher_status" => "yes_over_five_years",
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
        "aso_headteacher" => "yes",
        "aso_new_headteacher" => "no",
        "can_share_choices" => "1",
        "chosen_provider" => "yes",
        "confirmed_email" => "user@example.com",
        "course_id" => Course.find_by_code(code: :EHCO).id.to_s,
        "date_of_birth" => "1980-12-13",
        "email" => "user@example.com",
        "full_name" => "John Doe",
        "institution_identifier" => "School-100000",
        "institution_location" => "manchester",
        "institution_name" => "",
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
end
