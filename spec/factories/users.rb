FactoryBot.define do
  factory :user do
    full_name { "John Doe" }
    sequence(:email) { |n| "user#{n}@example.com" }
    trn { "1234567" }
    date_of_birth { 30.years.ago }
  end
end
