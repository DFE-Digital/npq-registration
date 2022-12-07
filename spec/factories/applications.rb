require "securerandom"

FactoryBot.define do
  factory :application do
    application_for_school

    user
    course { Course.all.sample }
    lead_provider { LeadProvider.all.sample }
    headteacher_status { "no" }

    trait :with_ecf_id do
      ecf_id { SecureRandom.uuid }
    end

    trait :application_for_school do
      school { build(:school) }
      private_childcare_provider_urn { nil }

      works_in_school { true }
      works_in_childcare { false }
      nursery_type { nil }
    end

    trait :application_for_private_childcare_provider do
      school_urn { nil }
      private_childcare_provider { build(:private_childcare_provider) }

      works_in_school { false }
      works_in_childcare { true }
      nursery_type { Forms::NurseryType::KIND_OF_NURSERY_PRIVATE_OPTIONS.sample }
    end

    trait :application_for_public_childcare_provider do
      school { build(:school) }
      private_childcare_provider_urn { nil }

      works_in_school { false }
      works_in_childcare { true }
      nursery_type { Forms::NurseryType::KIND_OF_NURSERY_PUBLIC_OPTIONS.sample }
    end
  end
end
