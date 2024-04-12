FactoryBot.define do
  factory :user do
    sequence(:full_name) { |n| "John Doe #{n}" }
    sequence(:email) { |n| "user#{n}@example.com" }
    trn { "1234567" }
    date_of_birth { 30.years.ago }

    trait :with_ecf_id do
      ecf_id { SecureRandom.uuid }
    end

    trait :with_get_an_identity_id do
      transient do
        get_an_identity_id { SecureRandom.uuid }
      end

      uid { get_an_identity_id }
      provider { "tra_openid_connect" }
    end

    trait :with_random_name do
      full_name { Faker::Name.name }
    end
  end
end
