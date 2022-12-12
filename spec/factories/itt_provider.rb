FactoryBot.define do
  factory :itt_provider do
    sequence(:legal_name) { |n| "private childcare provider #{n}" }
    sequence(:operating_name) { |n| (10_000_000 + n).to_s }
    sequence(:approved) { true }
    sequence(:added) { 30.days.ago }
  end
end
