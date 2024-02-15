require "faker"
require "csv"

# Parallel Tests is seeding the database, so I am skipping this in the test environment
return if Rails.env.test?

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
  CSV.read(Rails.root.join("db/seeds/schools.csv"), headers: true).tap do |data|
    if Rails.env.review?
      Rails.logger.info("Importing 1000 schools")

      School.insert_all(data.first(1000).map(&:to_h))
    else
      Rails.logger.info("Importing #{data.length} schools")

      School.insert_all(data.map(&:to_h))
    end
  end
end

def seed_childcare_providers!
  CSV.read(Rails.root.join("db/seeds/private_childcare_providers.csv"), headers: true).tap do |data|
    if Rails.env.review?
      Rails.logger.info("Importing 1000 private childcare providers")

      PrivateChildcareProvider.insert_all(data.first(1000).map(&:to_h))
    else
      Rails.logger.info("Importing #{data.length} private childcare providers")

      PrivateChildcareProvider.insert_all(data.map(&:to_h))
    end
  end
end

# IDs have been hard coded to be the same across all envs
seed_childcare_providers!
seed_schools
seed_courses!
seed_lead_providers!
seed_itt_providers!

if Rails.env.development?
  otp_testing_code = "00000"

  # Create admin user
  Admin.create!(
    email: "admin@example.com",
    full_name: "example admin",
    otp_hash: otp_testing_code,
    otp_expires_at: "3000-01-01 00:00:00.000000000 +0000",
    super_admin: false,
  )

  # Create admin user
  Admin.create!(
    email: "superadmin@example.com",
    full_name: "example super admin",
    otp_hash: otp_testing_code,
    otp_expires_at: "3000-01-01 00:00:00.000000000 +0000",
    super_admin: true,
  )

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
    lead_provider_approval_status: "accepted",
    participant_outcome_state: "passed",
  )

  outcome_states = %w[passed failed]
  approval_statuses = %w[accepted rejected]

  15.times do
    Application.create!(
      user: multiple_app_user,
      ecf_id: SecureRandom.uuid,
      lead_provider: LeadProvider.all.sample,
      course: Course.all.sample,
      work_setting: school_settings.sample,
      lead_provider_approval_status: approval_statuses.sample,
      participant_outcome_state: outcome_states.sample,
    )
  end
end
