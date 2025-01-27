FactoryBot.define do
  factory :school do
    sequence(:name) { |n| Faker::Educator.primary_school + " #{n}" }
    sequence(:urn) { rand(100_000..999_999).to_s }
    sequence(:ukprn) { rand(10_000_000..99_999_999).to_s }
    establishment_status_code { "1" }
    last_changed_date { Date.new(2010, 1, 1) }

    trait :funding_eligible_establishment_type_code do
      establishment_type_code { "1" }
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
