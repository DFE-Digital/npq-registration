FactoryBot.define do
  factory :declaration do
    transient do
      user { create(:user) }
      course { create(:course) }
      statement { nil }
      paid_statement { nil }
    end

    application { association :application, :accepted, user:, course: }
    lead_provider { application&.lead_provider || create(:lead_provider) }
    cohort { application&.cohort || create(:cohort, :current, :without_funding_cap) }
    delivery_partner { create(:delivery_partner, lead_providers: { cohort => lead_provider }) }
    declaration_type { "started" }
    declaration_date { Date.current }
    state { "submitted" }
    ecf_id { SecureRandom.uuid }

    after(:create) do |declaration, evaluator|
      if evaluator.statement && declaration.state != "submitted"
        if declaration.state.in? %w[awaiting_clawback clawed_back]
          raise ArgumentError, "Declaration state #{declaration.state} also requires paid_statement" if evaluator.paid_statement.nil?

          create(:statement_item, declaration:, state: "paid", statement: evaluator.paid_statement)
        end

        create(:statement_item, declaration:, state: declaration.state, statement: evaluator.statement)
      end
    end

    trait :submitted_or_eligible do
      state do
        if application && application.eligible_for_funding && application.funded_place
          :eligible
        else
          :submitted
        end
      end
    end

    trait :payable do
      state { :payable }
    end

    trait :paid do
      state { :paid }
    end

    trait :ineligible do
      state { :ineligible }
    end

    trait :voided do
      state { :voided }
    end

    trait :completed do
      declaration_type { :completed }
    end

    trait :from_ecf do
      ecf_id { SecureRandom.uuid }
    end

    trait :awaiting_clawback do
      state { :awaiting_clawback }
    end

    trait :voided do
      state { :voided }
    end

    trait :with_delivery_partner do
      delivery_partner { create(:delivery_partner, lead_providers: { cohort => lead_provider }) }
    end
  end
end
