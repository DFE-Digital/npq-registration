RSpec.shared_context("with stubbed Teacher Auth OmniAuth responses") do
  let(:user_first_name) { "John" }
  let(:user_last_name) { "Doe" }
  let(:user_previous_names) { [] }
  let(:user_full_name) { "#{user_first_name} #{user_last_name}" }
  let(:user_email) { "user@example.com" }
  let(:user_uid) { "urn:fdc:gov.uk:2022:#{SecureRandom.alphanumeric(43)}" }
  let(:user_date_of_birth) { "1980-12-13" }
  let(:user_date_of_birth_parsed) { Date.new(1980, 12, 13) }
  let(:user_trn) { "1234567" }
  let(:user_trn_lookup_status) { "Found" }

  let(:provider) { :teacher_auth }

  let(:stubbed_callback_response) do
    {
      "provider" => provider,
      "uid" => user_uid,
      "info" => {
        "email" => user_email,
      },
      "credentials" => {
        "token" => "some-token",
        "expires_in" => 3600,
        "scope" => "email openid profile teaching_record",
      },
      "extra" => {
        "raw_info" => {
          "sub" => user_uid,
          "trn" => user_trn,
          "email" => user_email,
          "verified_name" => [user_first_name, user_last_name],
          "verified_date_of_birth" => user_date_of_birth,
          "iss" => "https://preprod.authorise-access-to-a-teaching-record.education.gov.uk/",
          "exp" => 15.minutes.from_now.to_i,
          "iat" => 15.minutes.from_now.to_i,
          "aud" => "register-npq",
          "azp" => "register-npq",
        },
      },
    }
  end

  let(:stubbed_callback_response_as_json) do
    stubbed_callback_response.as_json
  end

  let(:user_attributes_from_stubbed_callback_response) do
    {
      "email" => user_email,
      "full_name" => user_full_name,
      "provider" => provider.to_s,
      "trn" => user_trn,
      "uid" => user_uid,
    }
  end

  before do
    OmniAuth.config.test_mode = true
    OmniAuth.config.add_mock(:teacher_auth, stubbed_callback_response)
  end
end
