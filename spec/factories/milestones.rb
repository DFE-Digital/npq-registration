FactoryBot.define do
  factory :milestone do
    declaration_type { :started }
    association(:schedule)
  end
end
