FactoryBot.define do
  factory :statement do
    month { Faker::Number.between(from: 1, to: 12) }
    year { Faker::Number.between(from: 2021, to: 2024) }
    deadline_date { Faker::Date.forward(days: 30) }
    payment_date { Faker::Date.forward(days: 30) }
    cohort { association :cohort }
    lead_provider { association :lead_provider }
    reconcile_amount { Faker::Number.decimal(l_digits: 3, r_digits: 2) }
    state { "open" }
    ecf_id { SecureRandom.uuid }
    output_fee { true }

    trait(:paid) do
      state { "paid" }
      marked_as_paid_at { 1.week.ago }
    end

    trait(:open) { state { "open" } }
    trait(:payable) { state { "payable" } }

    trait(:with_existing_lead_provider) do
      lead_provider { LeadProvider.all.sample }
    end
  end
end
