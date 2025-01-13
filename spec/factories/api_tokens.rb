FactoryBot.define do
  factory :api_token do
    lead_provider { create(:lead_provider) }
    hashed_token { Devise.token_generator.digest(APIToken, :hashed_token, "token") }

    trait :teacher_record_service do
      scope { APIToken.scopes[:teacher_record_service] }
      hashed_token { Devise.token_generator.digest(APIToken, :hashed_token, "trs_token") }
    end
  end
end
