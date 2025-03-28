# Be sure to restart your server when you modify this file.

# Configure sensitive parameters which will be filtered from the log file.
Rails.application.config.filter_parameters += %i[
  password
  passw
  secret
  token
  _key
  crypt
  salt
  certificate
  otp
  ssn
  national_insurance_number
  nino
  to
  cc
  bcc
  full_name
  key
  code
  trn
]
