FactoryBot.define do
  factory :private_childcare_provider do
    sequence(:provider_name) { |n| "private childcare provider #{n}" }
    sequence(:provider_urn) { |n| (100_000 + n).to_s }
    provider_status { "Active" }

    trait :on_early_years_register do
      early_years_individual_registers { %w[EYR] }
    end

    trait :on_all_registers do
      early_years_individual_registers { %w[CCR VCR EYR] }
    end
  end
end
