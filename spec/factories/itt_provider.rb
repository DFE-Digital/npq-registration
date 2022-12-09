FactoryBot.define do
  factory :itt_provider do
    sequence(:legal_name) { |n| "private childcare provider #{n}" }
    operating_name { legal_name }
    sequence(:approved) { true }
  end
end
