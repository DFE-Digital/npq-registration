FactoryBot.define do
  factory :statement do
    transient do
      declaration {}
    end

    after(:create) do |statement, evaluator|
      if evaluator.declaration
        create(:statement_item, declaration: evaluator.declaration, statement:)
      end
    end

    month { Faker::Number.between(from: 1, to: 12) }
    year { Faker::Number.between(from: 2022, to: 2024) }
    deadline_date { Date.new(year, month, 1) - 6.days }
    payment_date { Date.new(year, month, 25) }
    cohort { create(:cohort, :current) }
    lead_provider { declaration&.lead_provider || build(:lead_provider) }
    reconcile_amount { Faker::Number.decimal(l_digits: 3, r_digits: 2) }
    state { "open" }
    ecf_id { SecureRandom.uuid }
    output_fee { true }

    trait(:next_output_fee) do
      next_period
      output_fee { true }
    end

    trait(:next_period) do
      transient do
        latest_statement do
          existing = Statement.where(cohort:, lead_provider:).order(year: :desc, month: :desc)
          existing.first || OpenStruct.new(year: cohort.start_year, month: 1)
        end
      end

      month { latest_statement.month == 12 ? 1 : latest_statement.month + 1 }
      year { latest_statement.month == 12 ? latest_statement.year + 1 : latest_statement.year }
    end

    trait(:paid) do
      state { "paid" }
      marked_as_paid_at { 1.week.ago }
    end

    trait(:open) { state { "open" } }

    trait :payable do
      state { "payable" }
      deadline_date { Time.zone.yesterday }
    end

    trait(:with_existing_lead_provider) do
      lead_provider { LeadProvider.all.sample }
    end
  end
end
