require "faker"

def seed_courses!
  CourseService::DefinitionLoader.call
end

def seed_lead_providers!
  LeadProviders::Updater.call
end

def seed_itt_providers!
  file_name = "lib/approved_itt_providers/24-11-2022/approved_itt_providers.csv"
  ApprovedIttProviders::Update.call(file_name:)
end

def seed_schools
  require 'zip'
  zip_file_path = Rails.root.join('db', 'seeds', 'schools.zip')
  Zip::File.open(zip_file_path) do |zip_file|
    zip_file.first.tap do |entry|
      schools_data = JSON.parse(entry.get_input_stream.read)
      puts 'Importing schools data...'
      School.insert_all(schools_data)
      puts 'Schools data imported successfully.'
    end
  end
end

# IDs have been hard coded to be the same across all envs
seed_schools
seed_courses!
seed_lead_providers!
seed_itt_providers!

if Rails.env.development?
  otp_testing_code = "00000"

  # Create admin user
  User.create!(
    email: "admin@example.com",
    ecf_id: nil,
    trn: nil,
    full_name: "example admin",
    otp_hash: otp_testing_code,
    otp_expires_at: "3000-01-01 00:00:00.000000000 +0000",
    date_of_birth: "1962-02-10",
    trn_verified: false,
    active_alert: false,
    national_insurance_number: nil,
    trn_auto_verified: false,
    admin: true,
    super_admin: true,
    feature_flag_id: SecureRandom.uuid,
    provider: nil,
    uid: nil,
    raw_tra_provider_data: nil,
    get_an_identity_id_synced_to_ecf: false,
  )

  # Create childcare providers
  10.times do
    PrivateChildcareProvider.create!(
      provider_urn: "EY#{Faker::Number.number(digits: 5)}",
      provider_name: Faker::Educator.secondary_school,
      registered_person_urn: Faker::Number.number(digits: 7),
      registered_person_name: Faker::Educator.university,
      registration_date: "04/01/1995",
      provider_status: "Active",
      address_1: Faker::Address.secondary_address,
      address_2: Faker::Address.street_address,
      address_3: nil,
      town: Faker::Address.city,
      postcode: Faker::Address.postcode,
      postcode_without_spaces: Faker::Address.postcode.delete(" "),
      region: Faker::Address.state,
      local_authority: Faker::Address.city,
      ofsted_region: nil,
      early_years_individual_registers: %w[CCR VCR EYR].sample,
      provider_early_years_register_flag: false,
      provider_compulsory_childcare_register_flag: false,
      places: 30,
    )
  end

  single_app_user = User.create!(
    email: "user@example.com",
    ecf_id: SecureRandom.uuid,
    trn: "1234567",
    full_name: Faker::Name.name,
    otp_hash: otp_testing_code,
    otp_expires_at: "3000-01-01 00:00:00.000000000 +0000",
    date_of_birth: "1988-07-10",
    trn_verified: true,
    active_alert: false,
    national_insurance_number: nil,
    trn_auto_verified: false,
    admin: false,
    feature_flag_id: SecureRandom.uuid,
    provider: LeadProvider.all[6],
    uid: SecureRandom.uuid,
    raw_tra_provider_data: nil,
    get_an_identity_id_synced_to_ecf: false,
  )

  multiple_app_user = User.create!(
    email: "user2@example.com",
    ecf_id: SecureRandom.uuid,
    trn: "1234567",
    full_name: Faker::Name.name,
    otp_hash: otp_testing_code,
    otp_expires_at: "3000-01-01 00:00:00.000000000 +0000",
    date_of_birth: "1993-07-14",
    trn_verified: true,
    active_alert: false,
    national_insurance_number: nil,
    trn_auto_verified: false,
    admin: false,
    feature_flag_id: SecureRandom.uuid,
    provider: LeadProvider.all[4],
    uid: SecureRandom.uuid,
    raw_tra_provider_data: nil,
    get_an_identity_id_synced_to_ecf: false,
  )

  school_settings = %w[a_school an_academy_trust a_16_to_19_educational_setting]

  Application.create!(
    user: single_app_user,
    ecf_id: SecureRandom.uuid,
    lead_provider: LeadProvider.last,
    course: Course.all.sample,
    work_setting: school_settings.sample,
  )

  5.times do
    Application.create!(
      user: multiple_app_user,
      ecf_id: SecureRandom.uuid,
      lead_provider: LeadProvider.all.sample,
      course: Course.all.sample,
      work_setting: school_settings.sample,
    )
  end
end
