FactoryBot.define do
  factory :api_token do
    transient do
      raw_token { "token" }
    end

    lead_provider { create(:lead_provider) }
    hashed_token { Devise.token_generator.digest(APIToken, :hashed_token, raw_token) }

    trait :teacher_record_service do
      raw_token { "trs_token" }
      lead_provider { nil }
      scope { APIToken.scopes[:teacher_record_service] }
    end
  end
end
