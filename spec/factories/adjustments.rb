FactoryBot.define do
  factory :adjustment do
    sequence(:description) { |n| "Adjustment #{n}" }
    amount { 100 }
    statement { association(:statement) }
  end
end
