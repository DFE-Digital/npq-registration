# frozen_string_literal: true

FactoryBot.define do
  factory :ecf_migration_milestone, class: "Migration::Ecf::Finance::Milestone" do
    sequence(:name) { |n| "Milestone #{n}" }
    start_date { 1.day.ago }
    payment_date { 1.day.from_now }
    schedule { create(:ecf_migration_schedule) }
  end
end
