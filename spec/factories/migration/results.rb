FactoryBot.define do
  factory :migration_result, class: "Migration::Result" do
    trait :complete do
      completed_at { 1.day.ago }
    end

    trait :incomplete do
      completed_at { nil }
    end
  end
end
