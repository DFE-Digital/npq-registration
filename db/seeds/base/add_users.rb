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

@single_app_user = User.create!(
  email: "user@example.com",
  ecf_id: SecureRandom.uuid,
  trn: "1234567",
  full_name: Faker::Name.name,
  date_of_birth: "1988-07-10",
  trn_verified: true,
  active_alert: false,
  national_insurance_number: nil,
  trn_auto_verified: false,
  feature_flag_id: SecureRandom.uuid,
  provider: LeadProvider.all[6],
  uid: SecureRandom.uuid,
  raw_tra_provider_data: nil,
  get_an_identity_id_synced_to_ecf: false,
)

@multiple_app_user = User.create!(
  email: "user2@example.com",
  ecf_id: SecureRandom.uuid,
  trn: "1234567",
  full_name: Faker::Name.name,
  date_of_birth: "1993-07-14",
  trn_verified: true,
  active_alert: false,
  national_insurance_number: nil,
  trn_auto_verified: false,
  feature_flag_id: SecureRandom.uuid,
  provider: LeadProvider.all[4],
  uid: SecureRandom.uuid,
  raw_tra_provider_data: nil,
  get_an_identity_id_synced_to_ecf: false,
)
