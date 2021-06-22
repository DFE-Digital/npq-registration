FactoryBot.define do
  factory :school do
    sequence(:name) { |n| "school #{n}" }
    sequence(:urn) { |n| (100_000 + n).to_s }
    establishment_status_code { %w[1 3 4].sample }

    trait :closed do
      establishment_status_code { 2 }
    end
  end
end
