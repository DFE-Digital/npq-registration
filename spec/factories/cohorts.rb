FactoryBot.define do
  factory :cohort do
    start_year { Faker::Number.between(from: 2010, to: 2030) }
    created_at { Faker::Time.between(from: 2.years.ago, to: Time.zone.now) }
    updated_at { created_at }
  end
end
