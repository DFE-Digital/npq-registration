FactoryBot.define do
  factory :milestones_statement do
    association(:milestone)
    association(:statement)
  end
end
