# frozen_string_literal: true

FactoryBot.define do
  factory :ecf_migration_schedule, class: "Migration::Ecf::Finance::Schedule" do
    sequence(:name) { |n| "NPQ Finance Schedule #{n}" }
    cohort { create(:ecf_migration_cohort) }
    sequence(:schedule_identifier) { |n| "schedule-identifier-#{n}" }
    type { "Finance::Schedule::NPQ" }
  end
end
