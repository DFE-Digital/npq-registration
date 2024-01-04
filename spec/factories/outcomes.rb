FactoryBot.define do
  factory :outcome do
    declaration { association(:declaration) }
    completion_date { Date.tomorrow }
  end
end
