FactoryBot.define do
  factory :ecf_user, class: "Migration::Ecf::User" do
    full_name { Faker::Name.name }
    email { Faker::Internet.unique.email }

    trait :teacher do
      teacher_profile { create(:ecf_teacher_profile) }
    end

    trait :with_application do
      after(:create) do |user|
        participant_identity = create(:ecf_participant_identity, user:)
        create(:ecf_npq_application, participant_identity:)
      end
    end
  end
end
