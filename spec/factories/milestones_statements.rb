FactoryBot.define do
  factory :milestone_statement do
    association(:milestone)
    association(:statement)
  end
end
