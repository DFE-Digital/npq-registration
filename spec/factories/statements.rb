FactoryBot.define do
  factory :statement do
    transient do
      declaration {}
      sequence(:months_from_start_of_2021) { |n| (n - 1) % 48 }
      for_date { nil }
      extend_from { nil }
    end

    after :create do |statement, evaluator|
      if evaluator.declaration
        evaluator.declaration.mark_eligible! if evaluator.declaration.submitted?

        create(:statement_item, declaration: evaluator.declaration,
                                state: evaluator.declaration.state,
                                statement:)
      end
    end

    month do
      if for_date
        for_date.month
      elsif extend_from
        extend_from.month % 12 + 1
      else
        months_from_start_of_2021 % 12 + 1
      end
    end

    year do
      if for_date
        for_date.year
      elsif extend_from
        extend_from.year + extend_from.month / 12
      else
        2021 + months_from_start_of_2021 / 12
      end
    end

    deadline_date { extend_from ? (extend_from.deadline_date + 1.month) : Faker::Date.forward(days: 30) }
    payment_date { deadline_date ? deadline_date + 3.days : Faker::Date.forward(days: 30) }
    cohort { extend_from&.cohort || create(:cohort, :current) }
    lead_provider { extend_from&.lead_provider || declaration&.lead_provider || build(:lead_provider) }
    reconcile_amount { Faker::Number.decimal(l_digits: 3, r_digits: 2) }
    state { "open" }
    ecf_id { SecureRandom.uuid }
    output_fee { true }

    trait :next_output_fee do
      deadline_date { 1.day.from_now }
      output_fee { true }
    end

    trait :paid do
      state { "paid" }
      marked_as_paid_at { 1.week.ago }
    end

    trait(:open) { state { "open" } }

    trait :payable do
      state { "payable" }
      deadline_date { extend_from ? (extend_from.deadline_date + 1.month) : Time.zone.yesterday }
    end

    trait :with_existing_lead_provider do
      lead_provider { LeadProvider.first }
    end

    trait :has_targeted_delivery_funding do
      cohort { create(:cohort, :has_targeted_delivery_funding) }
      year { 2025 }
      month { 9 }
    end

    trait :with_milestones do
      after :create do |statement|
        create_list(:milestone_statement, 2, statement:)
      end
    end
  end
end
