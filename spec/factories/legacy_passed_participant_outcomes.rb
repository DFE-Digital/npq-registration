FactoryBot.define do
  factory :legacy_passed_participant_outcome do
    sequence(:trn) { rand(1_000_000..9_999_999).to_s }
    course_short_code { "NPQLT" }
    completion_date { Time.zone.today }
  end
end
