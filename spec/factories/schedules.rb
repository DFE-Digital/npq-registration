FactoryBot.define do
  factory :schedule do
    name { "Test Schedule" }
    declaration_start_date { Time.zone.today }
    starts_on { Time.zone.today + 1.week }
    ends_on { Time.zone.today + 1.month }
    declaration_types { %w[created] }
    course_group
    cohort
  end
end
