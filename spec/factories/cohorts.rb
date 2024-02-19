FactoryBot.define do
  factory :cohort do
    start_year { Faker::Number.between(from: 2022, to: 2025) }
    registration_start_date do
      start_year_date = Date.new(start_year, 1, 1)

      Faker::Date.between(from: start_year_date, to: start_year_date - 1.month)
    end
    created_at { Faker::Time.between(from: 2.years.ago, to: Time.zone.now) }
    updated_at { created_at }
  end
end
