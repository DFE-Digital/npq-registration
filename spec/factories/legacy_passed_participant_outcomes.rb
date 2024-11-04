FactoryBot.define do
  factory :legacy_passed_participant_outcome do
    trn { generate(:trn) }
    course_short_code { "NPQLT" }
    completion_date { Time.zone.today }
  end
end
