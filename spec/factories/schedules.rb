FactoryBot.define do
  factory :schedule do
    course_group
    cohort { create(:cohort, :current) }

    sequence(:name) { |n| "Schedule #{n}" }
    sequence(:identifier) { |n| "schedule-#{n}" }

    applies_from { Date.new(cohort.start_year, 10, 1) }
    applies_to { Date.new(cohort.start_year, 11, 1) }

    allowed_declaration_types { %w[started retained-1 retained-2 completed] }

    initialize_with do
      Schedule.find_by(cohort:, identifier:) || new(**attributes)
    end

    trait :npq_aso_december do
      name { "NPQ ASO December" }
      identifier { "npq-aso-december" }

      course_group { CourseGroup.find_by(name: "support") || create(:course_group, name: "support") }

      applies_from { Date.new(cohort.start_year, 12, 1) }
      applies_to { Date.new(cohort.start_year, 12, 1) }
    end

    trait :npq_aso_june do
      name { "NPQ ASO June" }
      identifier { "npq-aso-june" }

      course_group { CourseGroup.find_by(name: "support") || create(:course_group, name: "support") }

      applies_from { Date.new(cohort.start_year + 1, 6, 1) }
      applies_to { Date.new(cohort.start_year + 1, 6, 1) }
    end

    trait :npq_aso_march do
      name { "NPQ ASO March" }
      identifier { "npq-aso-march" }

      course_group { CourseGroup.find_by(name: "support") || create(:course_group, name: "support") }

      applies_from { Date.new(cohort.start_year + 1, 3, 1) }
      applies_to { Date.new(cohort.start_year + 1, 3, 1) }
    end

    trait :npq_aso_november do
      name { "NPQ ASO November" }
      identifier { "npq-aso-november" }

      course_group { CourseGroup.find_by(name: "support") || create(:course_group, name: "support") }

      applies_from { Date.new(cohort.start_year, 11, 1) }
      applies_to { Date.new(cohort.start_year, 11, 1) }
    end

    trait :npq_ehco_december do
      name { "NPQ EHCO December" }
      identifier { "npq-ehco-december" }

      course_group { CourseGroup.find_by(name: "ehco") || create(:course_group, name: "ehco") }

      applies_from { Date.new(cohort.start_year, 12, 1) }
      applies_to { Date.new(cohort.start_year, 12, 1) }
    end

    trait :npq_ehco_june do
      name { "NPQ EHCO June" }
      identifier { "npq-ehco-june" }

      course_group { CourseGroup.find_by(name: "ehco") || create(:course_group, name: "ehco") }

      applies_from { Date.new(cohort.start_year + 1, 6, 1) }
      applies_to { Date.new(cohort.start_year + 1, 6, 1) }
    end

    trait :npq_ehco_march do
      name { "NPQ EHCO March" }
      identifier { "npq-ehco-march" }

      course_group { CourseGroup.find_by(name: "ehco") || create(:course_group, name: "ehco") }

      applies_from { Date.new(cohort.start_year + 1, 3, 1) }
      applies_to { Date.new(cohort.start_year + 1, 3, 1) }
    end

    trait :npq_ehco_november do
      name { "NPQ EHCO November" }
      identifier { "npq-ehco-november" }

      course_group { CourseGroup.find_by(name: "ehco") || create(:course_group, name: "ehco") }

      applies_from { Date.new(cohort.start_year, 11, 1) }
      applies_to { Date.new(cohort.start_year, 11, 1) }
    end

    trait :npq_leadership_autumn do
      name { "NPQ Leadership Autumn" }
      identifier { "npq-leadership-autumn" }

      course_group { CourseGroup.find_by(name: "leadership") || create(:course_group, name: "leadership") }

      applies_from { Date.new(cohort.start_year, 10, 1) }
      applies_to { Date.new(cohort.start_year, 11, 1) }
    end

    trait :npq_leadership_spring do
      name { "NPQ Leadership Spring" }
      identifier { "npq-leadership-spring" }

      course_group { CourseGroup.find_by(name: "leadership") || create(:course_group, name: "leadership") }

      applies_from { Date.new(cohort.start_year + 1, 1, 1) }
      applies_to { Date.new(cohort.start_year + 1, 1, 1) }
    end

    trait :npq_specialist_autumn do
      name { "NPQ Specialist Autumn" }
      identifier { "npq-specialist-autumn" }

      course_group { CourseGroup.find_by(name: "specialist") || create(:course_group, name: "specialist") }

      applies_from { Date.new(cohort.start_year, 10, 1) }
      applies_to { Date.new(cohort.start_year, 11, 1) }

      allowed_declaration_types { %w[started retained-1 completed] }
    end

    trait :npq_specialist_spring do
      name { "NPQ Specialist Spring" }
      identifier { "npq-specialist-spring" }

      course_group { CourseGroup.find_by(name: "specialist") || create(:course_group, name: "specialist") }

      applies_from { Date.new(cohort.start_year + 1, 1, 1) }
      applies_to { Date.new(cohort.start_year + 1, 1, 1) }

      allowed_declaration_types { %w[started retained-1 completed] }
    end
  end
end
