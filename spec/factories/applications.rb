require "securerandom"

FactoryBot.define do
  factory :application do
    user
    course { Course.all.sample }
    lead_provider { LeadProvider.all.sample }
    school_urn { rand(100_000..999_999).to_s }
    headteacher_status { "no" }

    trait :with_ecf_id do
      ecf_id { SecureRandom.uuid }
    end
  end
end
