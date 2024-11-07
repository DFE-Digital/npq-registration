FactoryBot.define do
  factory :declaration do
    transient do
      user { create(:user) }
      course { create(:course) }
    end

    application { association :application, :accepted, user:, course: }
    lead_provider { application&.lead_provider || build(:lead_provider) }
    cohort { application&.cohort || build(:cohort, :current) }
    declaration_type { "started" }
    declaration_date { Date.current }
    state { "submitted" }
    ecf_id { SecureRandom.uuid }

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
  end
end
