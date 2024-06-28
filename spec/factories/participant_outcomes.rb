FactoryBot.define do
  factory :participant_outcome do
    passed
    completion_date { 1.week.ago }
    ecf_id { SecureRandom.uuid }

    declaration { association :declaration }

    trait :passed do
      state { "passed" }
    end

    trait :failed do
      state { "failed" }
    end

    trait :voided do
      state { "voided" }
    end
  end
end
