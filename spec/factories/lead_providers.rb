FactoryBot.define do
  factory :lead_provider do
    sequence(:name) { |i| "Lead Provider #{i}" }
  end
end
