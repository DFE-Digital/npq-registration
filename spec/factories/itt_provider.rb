FactoryBot.define do
  factory :itt_provider do
    sequence(:legal_name) { |n| "amazing ITT provider #{n}" }
    operating_name { legal_name }
    sequence(:approved) { true }
  end
end
