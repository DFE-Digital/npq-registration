FactoryBot.define do
  factory :statement do
    month { Faker::Number.between(from: 1, to: 12) }
    year { Faker::Number.between(from: 2022, to: 2024) }
    deadline_date { Faker::Date.forward(days: 30) }
    cohort { build :cohort}
    lead_provider { build :lead_provider }
    marked_as_paid_at { nil } # You can customize this attribute as needed
    reconcile_amount { Faker::Number.decimal(l_digits: 3, r_digits: 2) }
    created_at { Faker::Time.between(from: 2.years.ago, to: Time.zone.now) }
    updated_at { created_at }
    frozen_at { nil } # You can customize this attribute as needed
  end
end
