FactoryBot.define do
  factory :user do
    full_name { "John Doe" }
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

      uid { uid }
      provider { "tra_openid_connect" }
    end
  end

  factory :admin, class: "User" do
    full_name { "John Doe" }
    sequence(:email) { |n| "admin#{n}@example.com" }
    admin { true }

    trait :with_ecf_id do
      ecf_id { SecureRandom.uuid }
    end
  end
end
