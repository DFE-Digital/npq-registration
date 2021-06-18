FactoryBot.define do
  factory :application do
    user
    course { Course.all.sample }
    lead_provider { LeadProvider.all.sample }
    school_urn { rand(100_000..999_999).to_s }
    headteacher_status { "no" }
  end
end
