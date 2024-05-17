FactoryBot.define do
  factory :course do
    sequence(:name) { |n| "NPQ Course #{n}" }
    identifier { Course::IDENTIFIERS.sample }
    ecf_id { SecureRandom.uuid }
  end
end
