FactoryBot.define do
  factory :itt_provider do
    sequence(:legal_name) { |n| "ITT provider #{n}" }
    operating_name { legal_name }
    sequence(:approved) { true }

    initialize_with do
      IttProvider.find_by(legal_name:) || new(**attributes)
    end

    trait :disabled do
      disabled_at { 1.day.ago }
    end
  end
end
