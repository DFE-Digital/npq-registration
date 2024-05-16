# frozen_string_literal: true

FactoryBot.define do
  factory :ecf_migration_npq_course, class: "Migration::Ecf::NpqCourse" do
    sequence(:name) { |n| "NPQ Course #{n}" }
    identifier { Course::IDENTIFIERS.sample }
  end
end
