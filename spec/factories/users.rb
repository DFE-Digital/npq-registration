FactoryBot.define do
  factory :user do
    sequence(:full_name) { |n| "John Doe #{n}" }
    sequence(:email) { Faker::Internet.email(name: full_name) }
    trn { "1234567" }
    date_of_birth { 30.years.ago }
    ecf_id { SecureRandom.uuid }

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

    trait :with_verified_trn do
      trn_verified { true }
    end

    trait :with_application do
      transient do
        lead_provider { LeadProvider.all.sample }
      end

      after(:create) do |user, evaluator|
        create(:application, user:, lead_provider: evaluator.lead_provider)
      end
    end
  end
end
