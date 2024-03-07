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
    if Rails.env.in?(%w[review development])
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
    if Rails.env.in?(%w[review development])
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

if Rails.env.in?(%w[development review])
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

  # users with one application each
  FactoryBot.create_list(
    :application,
    20,
    :with_random_user,
    :with_random_work_setting,
    ecf_id: SecureRandom.uuid,
    lead_provider: LeadProvider.last,
    course: Course.all.sample,
    lead_provider_approval_status: "accepted",
    participant_outcome_state: "passed",
  )

  # a user with 4 applications
  FactoryBot.create_list(
    :application,
    4,
    :with_random_lead_provider_approval_status,
    :with_random_participant_outcome_state,
    :with_random_work_setting,
    user: FactoryBot.create(:user, :with_random_name),
    ecf_id: SecureRandom.uuid,
    lead_provider: LeadProvider.all.sample,
    course: Course.all.sample,
  )
end

Setting.create!(course_start_date: 3.months.from_now)

FactoryBot.create_list(:statement, 20)

# APIToken for testing
if Rails.env.in?(%w[development review])
  {
    "Ambition Institute" => "ambition-token",
    "Best Practice Network" => "best-practice-token",
    "Church of England" => "coe-token",
    "Education Development Trust" => "edt-token",
    "School-Led Network" => "school-led-token",
    "UCL Institute of Education" => "ucl-token",
    "Teacher Development Trust" => "tdt-token",
    "Teach First" => "teach-first-token",
    "National Institute of Teaching" => "niot-token",
    "LLSE" => "llse-token",
  }.each do |name, token|
    lead_provider = LeadProvider.where("name LIKE ?", "#{name}%").first!
    APIToken.create_with_known_token!(token, lead_provider:)
  end
end
