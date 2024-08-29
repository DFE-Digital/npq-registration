# frozen_string_literal: true

FactoryBot.define do
  factory :data_migration, class: "Migration::DataMigration" do
    model { "model" }
    worker { 0 }

    trait :in_progress do
      queued
      started_at { 30.days.ago }
      total_count { 100 }
    end

    trait :with_failures do
      in_progress
      failure_count { 1_234 }
    end

    trait :completed do
      in_progress
      completed_at { Time.zone.now }
    end

    trait :queued do
      queued_at { Time.zone.now }
    end
  end
end
