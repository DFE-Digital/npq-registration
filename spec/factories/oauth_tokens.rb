FactoryBot.define do
  factory :oauth_token do
    user
    last_updated_token_at { Time.zone.now }
    sequence(:token) { |n| "MyToken#{n}" }
  end
end
