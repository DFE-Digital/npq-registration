FactoryBot.define do
  factory :ecf_user, class: "Migration::Ecf::User" do
    full_name { Faker::Name.name }
    email { Faker::Internet.unique.email }

    trait :teacher do
      teacher_profile { create(:ecf_teacher_profile) }
    end
  end
end
