FactoryBot.define do
  factory :oauth_token do
    user
    token { SecureRandom.hex(32) }
    token_updated_at { Time.current }
  end
end
