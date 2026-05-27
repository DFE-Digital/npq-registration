FactoryBot.define do
  factory :oauth_token do
    user
    token { SecureRandom.hex(32) }
    token_updated_at { Time.current }

    trait :stale do
      token_updated_at { (OauthToken::REFRESH_LIFETIME + 2.hours).ago }
    end

    trait :fresh do
      token_updated_at { (OauthToken::REFRESH_LIFETIME - 2.hours).ago }
    end
  end
end
