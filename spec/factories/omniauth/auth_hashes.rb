FactoryBot.define do
  factory :omniauth_auth_hash, class: "OmniAuth::AuthHash" do
    to_create { self }

    transient do
      id_token { "testing-id-token" }
      trn { "1234567" }
    end

    uid { "urn:fdc:gov.uk:2022:#{SecureRandom.alphanumeric(43)}" }

    extra do
      {
        "raw_info" => {
          "trn" => trn,
        }.compact,
      }
    end

    credentials do
      {
        "id_token" => id_token,
      }.compact
    end
  end
end
