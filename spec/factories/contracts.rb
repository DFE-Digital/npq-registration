FactoryBot.define do
  factory :contract do
    association :statement
    association :course
    association :contract_template
  end
end
