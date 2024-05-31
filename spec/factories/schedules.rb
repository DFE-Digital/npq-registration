FactoryBot.define do
  factory :schedule do
    course_group
    cohort

    sequence(:name) { |n| "Schedule #{n}" }
    sequence(:identifier) { |n| "schedule-#{n}" }

    applies_from { nil }
    applies_to { nil }

    allowed_declaration_types { %w[started retained-1 retained-2 completed] }
  end
end
