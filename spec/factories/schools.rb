FactoryBot.define do
  sequence(:urn) { |n| sprintf("1%05d", n % 1_000_000) }
  sequence(:ukprn) { |n| sprintf("%08d", n % 100_000_000) }

  factory :school do
    sequence(:name) { |n| Faker::Educator.primary_school + " #{n}" }
    urn { generate(:urn) }
    ukprn { generate(:ukprn) }
    establishment_status_code { "1" }
    last_changed_date { Date.new(2010, 1, 1) }

    trait :non_pp50 do
      urn do
        urn = nil

        loop do
          urn = generate(:urn)
          break unless PP50_SCHOOLS_URN_HASH[urn.to_s]
        end

        urn
      end

      ukprn do
        ukprn = nil

        loop do
          ukprn = generate(:ukprn)
          break unless PP50_FE_UKPRN_HASH[ukprn.to_s]
        end

        ukprn
      end
    end

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
