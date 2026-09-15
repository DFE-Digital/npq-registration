FactoryBot.define do
  factory :milestone do
    transient do
      for_statement { nil }
    end

    declaration_type { :started }

    schedule do
      cohort = Array.wrap(for_statement).first&.cohort
      kwargs = cohort ? { cohort: } : {}
      association :schedule, **kwargs
    end

    after :create do |milestone, evaluator|
      Array.wrap(evaluator.for_statement).each do |statement|
        milestone.statements << statement
      end
    end
  end
end
