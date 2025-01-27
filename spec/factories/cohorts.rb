FactoryBot.define do
  factory :cohort do
    sequence(:start_year, 0) { |n| 2021 + n % 9 }
    registration_start_date { Date.new(start_year, 4, 3) }

    initialize_with do
      Cohort.find_or_create_by(start_year:)
    end

    trait :current do
      start_year { Date.current.month < 9 ? Date.current.year.pred : Date.current.year }
    end

    trait :next do
      start_year { Date.current.month < 9 ? Date.current.year : Date.current.year.succ }
    end

    trait :previous do
      start_year { Date.current.month < 9 ? Date.current.year : (Date.current.year - 1) }
    end

    trait :with_funding_cap do
      funding_cap { true }
    end
  end
end
