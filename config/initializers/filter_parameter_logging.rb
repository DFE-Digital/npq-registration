# Be sure to restart your server when you modify this file.

# Configure parameters to be partially matched (e.g. passw matches password) and filtered from the log file.
# Use this to limit dissemination of sensitive information.
# See the ActiveSupport::ParameterFilter documentation for supported notations and behaviors.
Rails.application.config.filter_parameters += [
  /\Abcc\z/,
  /\Acc\z/,
  /\Acode\z/,
  /\Acvc\z/,
  /\Acvv\z/,
  /\Akey\z/,
  /\Anino\z/,
  /\Aotp\z/,
  /\Assn\z/,
  /\Ato\z/,
  /\Atrn\z/,
  :_key,
  :certificate,
  :crypt,
  :full_name,
  :national_insurance_number,
  :passw,
  :salt,
  :secret,
  :token,
]
