RSpec.shared_context("Stubbed TRA Omniauth Request") do
  let(:user_first_name) { "Avery" }
  let(:user_last_name) { "Smith" }
  let(:user_full_name) { "#{user_first_name} #{user_last_name}" }
  let(:user_email) { "averysmith@example.com" }
  let(:user_uid) { SecureRandom.uuid }

  let(:provider) { "tra_openid_connect" }

  let(:stubbed_callback_response) do
    {
      "provider" => provider,
      "uid" => user_uid,
      "info" => {
        "name" => user_full_name,
        "email" => user_email,
        "first_name" => user_first_name,
        "last_name" => user_last_name,
      },
      "credentials" => {
        "id_token" => SecureRandom.uuid,
        "token" => SecureRandom.uuid,
        "refresh_token" => nil,
        "expires_in" => 3599,
        "scope" => "email openid profile trn",
      },
      "extra" => {
        "raw_info" => {
          "sub" => SecureRandom.uuid,
          "email" => user_email,
          "email_verified" => "True",
          "name" => user_full_name,
          "given_name" => user_first_name,
          "family_name" => user_last_name,
          "birthdate" => rand(70.years.ago..18.years.ago).to_date.to_s,
          "oi_au_id" => SecureRandom.uuid,
          "azp" => "register-for-npq",
          "nonce" => SecureRandom.hex(16),
          "at_hash" => "-#{SecureRandom.hex(10)}",
          "oi_tkn_id" => SecureRandom.uuid,
          "aud" => "register-for-npq",
          "exp" => Time.current.to_i,
          "iss" => ENV.fetch("TRA_OIDC_DOMAIN", nil),
          "iat" => Time.current.to_i,
        },
      },
    }
  end

  before do
    OmniAuth.config.test_mode = true
    OmniAuth.config.add_mock(:tra_openid_connect, stubbed_callback_response)
  end
end
