# frozen_string_literal: true

FactoryBot.define do
  factory :ecf_migration_user, class: "Migration::Ecf::User" do
    email { Faker::Internet.unique.email }
    sequence(:full_name) { |n| "John Doe #{n}" }

    trait :npq do
      after(:create) do |user|
        user.teacher_profile = create(:ecf_migration_teacher_profile, user:, participant_profiles: [create(:ecf_migration_npq_participant_profile, user:)])
      end
    end

    trait :with_random_name do
      full_name { Faker::Name.name }
    end
  end
end
