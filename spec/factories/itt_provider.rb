FactoryBot.define do
  factory :itt_provider do
    sequence(:legal_name) { |n| "private childcare provider #{n}" }
    operating_name { legal_name }
    sequence(:approved) { true }
    sequence(:added) { 30.days.ago }
  end
end
