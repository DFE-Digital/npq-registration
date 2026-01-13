# Be sure to restart your server when you modify this file.

# NOTE: specifiying a symbol with match parameters that contain that word
# See the ActiveSupport::ParameterFilter documentation for supported notations and behaviors.
Rails.application.config.filter_parameters += [
  /\Abcc\z/,
  /\Acc\z/,
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
  :code,
  :crypt,
  :full_name,
  :national_insurance_number,
  :passw,
  :salt,
  :secret,
  :token,
]
