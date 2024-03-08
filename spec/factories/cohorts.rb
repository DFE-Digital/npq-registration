FactoryBot.define do
  factory :cohort do
    start_year { Faker::Number.between(from: 2021, to: 2029) }
    registration_start_date { Date.new(start_year, 4, 3) }

    initialize_with do
      Cohort.find_by(start_year:) || new(**attributes)
    end
  end
end
