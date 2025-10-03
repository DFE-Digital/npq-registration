FactoryBot.define do
  factory :eligibility_list do
    pp50_school

    trait :pp50_school do
      type { EligibilityList::Pp50School }
      sequence(:identifier) { |n| sprintf("1TEST%05d", n % 100_000) }
      identifier_type { "urn" }
    end

    trait :pp50_further_education do
      type { EligibilityList::Pp50FurtherEducation }
      sequence(:identifier) { |n| sprintf("TEST%08d", n % 100_000_000) }
      identifier_type { "ukprn" }
    end

    trait :childminder do
      type { EligibilityList::Childminder }
      sequence(:identifier) { |n| sprintf("1TEST%05d", n % 100_000) }
      identifier_type { "urn" }
    end

    trait :disadvantaged_early_years_school do
      type { EligibilityList::DisadvantagedEarlyYearsSchool }
      sequence(:identifier) { |n| sprintf("1TEST%05d", n % 100_000) }
      identifier_type { "urn" }
    end

    trait :local_authority_nursery do
      type { EligibilityList::LocalAuthorityNursery }
      sequence(:identifier) { |n| sprintf("1TEST%05d", n % 100_000) }
      identifier_type { "urn" }
    end

    trait :rise_school do
      type { EligibilityList::RiseSchool }
      sequence(:identifier) { |n| sprintf("1TEST%05d", n % 100_000) }
      identifier_type { "urn" }
    end
  end
end
