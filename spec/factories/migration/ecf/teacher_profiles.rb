# frozen_string_literal: true

FactoryBot.define do
  factory :ecf_migration_teacher_profile, class: "Migration::Ecf::TeacherProfile" do
    user { create(:ecf_migration_user) }
    trn { sprintf("%07i", Random.random_number(9_999_999)) }

    initialize_with do
      Migration::Ecf::TeacherProfile.find_by(user:) || new(**attributes)
    end
  end
end
