FactoryBot.define do
  factory :outcome do
    passed
    completion_date { Time.zone.today + 1.week }

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
