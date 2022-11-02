RSpec.shared_context("Disable Get An Identity integration") do
  before do
    allow(Services::Feature).to receive(:get_an_identity_integration_active_for?).and_return(false)
  end
end

RSpec.shared_context("Enable Get An Identity integration") do
  let(:user_full_name) { "John Doe" }
  let(:user_email) { "user@example.com" }
  let(:user_uid) { SecureRandom.uuid }
  let(:user_date_of_birth) { "1980-12-13" }
  let(:user_trn) { "1234567" }
  let(:user_nino) { "AB123456C" }

  let(:provider) { "tra_openid_connect" }

  let(:stubbed_callback_response) do
    {
      "provider" => "tra_openid_connect",
      "uid" => user_uid,
      "info" => {
        "date_of_birth" => user_date_of_birth,
        "email" => user_email,
        "email_verified" => true,
        "trn" => user_trn,
        "name" => user_full_name,
        "nino" => user_nino,
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
          "birthdate" => user_date_of_birth,
          "trn" => user_trn,
        },
      },
    }
  end

  before do
    allow(Services::Feature).to receive(:get_an_identity_integration_active_for?).and_return(true)

    OmniAuth.config.test_mode = true
    OmniAuth.config.add_mock(:tra_openid_connect, stubbed_callback_response)
  end
end
