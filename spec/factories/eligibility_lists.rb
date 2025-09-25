FactoryBot.define do
  factory :eligibility_list do
    pp50_school

    trait :pp50_school do
      eligibility_list_type { EligibilityList.eligibility_list_types[:pp50_school] }
      sequence(:identifier) { |n| sprintf("1TEST%05d", n % 100_000) }
      identifier_type { "urn" }
    end

    trait :pp50_further_education do
      eligibility_list_type { EligibilityList.eligibility_list_types[:pp50_further_education] }
      sequence(:identifier) { |n| sprintf("TEST%08d", n % 100_000_000) }
      identifier_type { "ukprn" }
    end

    trait :childminder do
      eligibility_list_type { EligibilityList.eligibility_list_types[:childminder] }
      sequence(:identifier) { |n| sprintf("1TEST%05d", n % 100_000) }
      identifier_type { "urn" }
    end

    trait :disadvantaged_early_years_school do
      eligibility_list_type { EligibilityList.eligibility_list_types[:disadvantaged_early_years_school] }
      sequence(:identifier) { |n| sprintf("1TEST%05d", n % 100_000) }
      identifier_type { "urn" }
    end

    trait :local_authority_nursery do
      eligibility_list_type { EligibilityList.eligibility_list_types[:local_authority_nursery] }
      sequence(:identifier) { |n| sprintf("1TEST%05d", n % 100_000) }
      identifier_type { "urn" }
    end

    trait :rise_school do
      eligibility_list_type { EligibilityList.eligibility_list_types[:rise_school] }
      sequence(:identifier) { |n| sprintf("1TEST%05d", n % 100_000) }
      identifier_type { "urn" }
    end
  end
end
