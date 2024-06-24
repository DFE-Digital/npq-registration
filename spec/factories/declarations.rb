FactoryBot.define do
  factory :declaration do
    application
    lead_provider { application&.lead_provider || build(:lead_provider) }
    cohort { application&.cohort || build(:cohort, :current) }

    declaration_type { "started" }
    declaration_date { Date.current }

    state { "submitted" }

    trait :eligible do
      state { :eligible }
    end

    trait :paid do
      state { :paid }
    end
  end
end
