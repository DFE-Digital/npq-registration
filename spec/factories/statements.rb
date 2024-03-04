FactoryBot.define do
  factory :statement do
    month { Faker::Number.between(from: 1, to: 12) }
    year { Faker::Number.between(from: 2022, to: 2024) }
    deadline_date { Faker::Date.forward(days: 30) }
    payment_date { Faker::Date.forward(days: 30) }
    cohort { association :cohort }
    lead_provider { association :lead_provider }
    marked_as_paid_at { nil }
    reconcile_amount { Faker::Number.decimal(l_digits: 3, r_digits: 2) }
    state { "open" }
  end
end
