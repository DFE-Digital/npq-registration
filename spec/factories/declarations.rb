FactoryBot.define do
  helpers = Class.new { include ActiveSupport::Testing::TimeHelpers }.new

  factory :declaration do
    transient do
      user { create(:user) }
      course { create(:course) }
      transient_application { create(:application, :accepted, user:, course:) }
    end

    application { transient_application }
    lead_provider { application&.lead_provider || build(:lead_provider) }
    cohort { application&.cohort || build(:cohort, :current) }
    declaration_type { "started" }
    declaration_date do
      schedule = application.schedule || transient_application.schedule
      schedule.applies_from + 1.day
    end
    state { "submitted" }

    trait :submitted_or_eligible do
      state do
        if application && application.eligible_for_funding && application.funded_place
          :eligible
        else
          :submitted
        end
      end
    end

    trait :paid do
      state { :paid }
    end

    trait :ineligible do
      state { :ineligible }
    end

    trait :completed do
      declaration_type { :completed }
    end

    after(:build) do |declaration, _context|
      helpers.travel_to(declaration.declaration_date)
    end
  end
end
