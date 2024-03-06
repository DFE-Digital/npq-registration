# frozen_string_literal: true

FactoryBot.define do
  factory :data_migration, class: "Migration::DataMigration" do
    model { "model" }

    trait :in_progress do
      started_at { 30.seconds.ago }
      total_count { 100 }
    end

    trait :with_failures do
      failure_count { 27 }
    end

    trait :completed do
      completed_at { Time.zone.now }
    end
  end
end
