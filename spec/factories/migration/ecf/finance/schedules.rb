# frozen_string_literal: true

FactoryBot.define do
  factory :ecf_migration_schedule, class: "Migration::Ecf::Finance::Schedule" do
    sequence(:name) { |n| "NPQ Finance Schedule #{n}" }
    cohort { create(:ecf_migration_cohort) }
    sequence(:schedule_identifier) { |n| "schedule-identifier-#{n}" }
    type { "Finance::Schedule::NPQ" }
  end

  factory :ecf_migration_schedule_npq_support, class: "Migration::Ecf::Finance::Schedule::NpqSupport" do
    sequence(:name) { |n| "NPQ Support Schedule #{n}" }
    cohort { create(:ecf_migration_cohort) }
    sequence(:schedule_identifier) { |n| "npq-support-schedule-identifier-#{n}" }
    type { "Finance::Schedule::NPQSupport" }
  end

  factory :ecf_migration_schedule_npq_specialist, class: "Migration::Ecf::Finance::Schedule::NpqSpecialist" do
    sequence(:name) { |n| "NPQ Specialist Schedule #{n}" }
    cohort { create(:ecf_migration_cohort) }
    sequence(:schedule_identifier) { |n| "npq-specialist-schedule-identifier-#{n}" }
    type { "Finance::Schedule::NPQSpecialist" }
  end

  factory :ecf_migration_schedule_npq_ehco, class: "Migration::Ecf::Finance::Schedule::NpqEhco" do
    sequence(:name) { |n| "NPQ Echo Schedule #{n}" }
    cohort { create(:ecf_migration_cohort) }
    sequence(:schedule_identifier) { |n| "npq-ehco-schedule-identifier-#{n}" }
    type { "Finance::Schedule::NPQEhco" }
  end

  factory :ecf_migration_schedule_npq_leadership, class: "Migration::Ecf::Finance::Schedule::NpqLeadership" do
    sequence(:name) { |n| "NPQ Leadership Schedule #{n}" }
    cohort { create(:ecf_migration_cohort) }
    sequence(:schedule_identifier) { |n| "npq-leadership-schedule-identifier-#{n}" }
    type { "Finance::Schedule::NPQLeadership" }
  end
end
