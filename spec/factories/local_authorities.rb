FactoryBot.define do
  factory :local_authority do
    sequence(:name) { |n| "local authority #{n}" }
    sequence(:ukprn) { |n| (10_000_000 + n).to_s }
  end
end
