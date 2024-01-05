FactoryBot.define do
  factory :ecf_teacher_profile, class: "Migration::Ecf::TeacherProfile" do
    user { create(:ecf_user) }
    trn { Faker::Number.unique.decimal_part(digits: 7) }
  end
end
