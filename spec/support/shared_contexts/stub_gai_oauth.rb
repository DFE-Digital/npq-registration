RSpec.shared_context("Stub Get An Identity Omniauth Responses") do
  let(:user_first_name) { "John" }
  let(:user_last_name) { "Doe" }
  let(:user_preferred_name) { "#{user_first_name} #{user_last_name}" }
  let(:user_full_name) { user_preferred_name || "#{user_first_name} #{user_last_name}" }
  let(:user_email) { "user@example.com" }
  let(:user_uid) { SecureRandom.uuid }
  let(:user_date_of_birth) { "1980-12-13" }
  let(:user_date_of_birth_parsed) { Date.new(1980, 12, 13) }
  let(:user_trn) { "1234567" }
  let(:user_trn_lookup_status) { "Found" }

  let(:provider) { "tra_openid_connect" }

  let(:stubbed_callback_response) do
    {
      "provider" => "tra_openid_connect",
      "uid" => user_uid,
      "info" => {
        "date_of_birth" => user_date_of_birth_parsed,
        "email" => user_email,
        "email_verified" => true,
        "trn" => user_trn,
        "name" => user_full_name,
        "preferred_name" => user_preferred_name,
        "trn_lookup_status" => user_trn_lookup_status,
      },
      "credentials" => {
        "token" => SecureRandom.uuid,
        "expires_at" => 24.days.from_now.to_i,
        "expires" => true,
      },
      "extra" => {
        "raw_info" => {
          "sub" => user_uid,
          "email" => user_email,
          "email_verified" => "True",
          "name" => user_full_name,
          "preferred_name" => user_preferred_name,
          "birthdate" => user_date_of_birth,
          "trn" => user_trn,
          "given_name" => user_first_name,
          "family_name" => user_last_name,
          "trn_lookup_status" => user_trn_lookup_status,
        },
      },
    }
  end

  let(:stubbed_callback_response_as_json) do
    stubbed_callback_response.as_json
  end

  let(:user_attributes_from_stubbed_callback_response) do
    {
      "date_of_birth" => user_date_of_birth,
      "email" => user_email,
      "full_name" => user_full_name,
      "preferred_name" => user_preferred_name,
      "provider" => "tra_openid_connect",
      "raw_tra_provider_data" => stubbed_callback_response_as_json,
      "trn" => user_trn,
      "trn_lookup_status" => user_trn_lookup_status,
      "uid" => user_uid,
    }
  end

  before do
    OmniAuth.config.test_mode = true
    OmniAuth.config.add_mock(:tra_openid_connect, stubbed_callback_response)
  end
end
