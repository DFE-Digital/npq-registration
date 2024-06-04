FactoryBot.define do
  factory :school do
    sequence(:name) { |n| "school #{n}" }
    sequence(:urn) { rand(100_000..999_999).to_s }
    sequence(:ukprn) { rand(10_000_000..99_999_999).to_s }
    establishment_status_code { %w[1 3 4].sample }

    trait :funding_eligible_establishment_type_code do
      establishment_type_code do
        %w[1 2 3 5 6 7 8 10 12 14 15 18 24 26 28 31 32 33 34 35 36 38 39 40 41 42 43 44 45 46].sample
      end
      eyl_funding_eligible { true }
    end

    trait :closed do
      establishment_status_code { 2 }
    end

    trait :with_address do
      address_1 { Faker::Address.building_number }
      address_2 { Faker::Address.street_address }
      address_3 { Faker::Address.community }
      town { "town" }
      county { "county" }
      postcode { Faker::Address.postcode }
    end
  end
end
