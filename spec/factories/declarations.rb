FactoryBot.define do
  helpers = Class.new { include ActiveSupport::Testing::TimeHelpers }.new

  factory :declaration do
    transient do
      user { create(:user) }
      course { create(:course) }
    end

    application { association :application, :accepted, user:, course:, cohort: build(:cohort, :previous) }
    lead_provider { application&.lead_provider || build(:lead_provider) }
    cohort { application&.cohort || build(:cohort, :previous) }
    declaration_type { "started" }
    declaration_date do
      date = application.schedule&.applies_from || Date.current
      date + 1.day
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

    to_create do |instance|
      helpers.travel_to(instance.declaration_date) { instance.save! }
    end
  end
end
