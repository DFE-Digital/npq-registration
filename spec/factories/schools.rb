FactoryBot.define do
  sequence(:urn) { |n| sprintf("1TEST%05d", n % 100_000) }
  sequence(:ukprn) { |n| sprintf("TEST%08d", n % 100_000_000) }

  factory :school do
    sequence(:name) { |n| Faker::Educator.primary_school + " #{n}" }
    urn { generate(:urn) }
    ukprn { generate(:ukprn) }
    establishment_status_code { "1" }
    last_changed_date { Date.new(2010, 1, 1) }

    trait :funding_eligible_establishment_type_code do
      establishment_type_code { "1" }
      eyl_funding_eligible { true }
    end

    trait :local_authority_nursery_school do
      establishment_type_code { "15" }
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
