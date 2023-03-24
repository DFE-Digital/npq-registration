require "faker"

def seed_courses!
  Services::Courses::DefinitionLoader.call
end

def seed_lead_providers!
  Services::LeadProviders::Updater.call
end

def seed_itt_providers!
  file_name = "lib/approved_itt_providers/24-11-2022/approved_itt_providers.csv"
  Services::ApprovedIttProviders::Update.call(file_name:)
end

# IDs have been hard coded to be the same across all envs
seed_courses!
seed_lead_providers!
seed_itt_providers!

# Create admin user
User.create!(
  email: "admin@example.com",
  ecf_id: nil,
  trn: nil,
  full_name: "example admin",
  otp_hash: "000000",
  otp_expires_at: "3000-01-01 00:00:00.000000000 +0000",
  date_of_birth: nil,
  trn_verified: false,
  active_alert: false,
  national_insurance_number: nil,
  trn_auto_verified: false,
  admin: true,
  flipper_admin_access: true,
  feature_flag_id: SecureRandom.uuid,
  provider: nil,
  uid: nil,
  raw_tra_provider_data: nil,
  get_an_identity_id_synced_to_ecf: false,
)

# Create childcare providers
# 10.times do
#   PrivateChildcareProvider.create!(
#     provider_urn: "EY#{Faker::Number.number(digits: 5)}",
#     provider_name: Faker::Educator.secondary_school,
#     registered_person_urn: Faker::Number.number(digits: 7),
#     registered_person_name: Faker::Educator.university,
#     registration_date: "04/01/1995",
#     provider_status: "Active",
#     address_1: Faker::Address.secondary_address,
#     address_2: Faker::Address.street_address,
#     address_3: nil,
#     town: Faker::Address.city,
#     postcode: Faker::Address.postcode,
#     postcode_without_spaces: Faker::Address.postcode.delete(" "),
#     region: Faker::Address.state,
#     local_authority: Faker::Address.city,
#     ofsted_region: nil,
#     early_years_individual_registers: %w[CCR VCR EYR].sample,
#     provider_early_years_register_flag: false,
#     provider_compulsory_childcare_register_flag: false,
#     places: 30,
#   )
# end
