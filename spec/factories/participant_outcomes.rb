FactoryBot.define do
  factory :participant_outcome do
    transient do
      user { create(:user) }
      lead_provider { create(:lead_provider) }
      course { Course.find_by!(identifier: ParticipantOutcomes::Create::PERMITTED_COURSES.sample) }
      cohort { create(:cohort, :previous) }
      application { create(:application, :accepted, user:, course:, lead_provider:, cohort:) }
    end

    passed
    completion_date { 1.week.ago }
    ecf_id { SecureRandom.uuid }
    declaration { association :declaration, :completed, :payable, lead_provider:, course:, user:, application: }

    trait :passed do
      state { "passed" }
    end

    trait :failed do
      state { "failed" }
    end

    trait :voided do
      state { "voided" }
    end

    trait :sent_to_qualified_teachers_api do
      sent_to_qualified_teachers_api_at { Time.zone.now - 1.hour }
    end

    trait :not_sent_to_qualified_teachers_api do
      sent_to_qualified_teachers_api_at { nil }
    end

    trait :successfully_sent_to_qualified_teachers_api do
      sent_to_qualified_teachers_api
      qualified_teachers_api_request_successful { true }
    end

    trait :unsuccessfully_sent_to_qualified_teachers_api do
      sent_to_qualified_teachers_api
      qualified_teachers_api_request_successful { false }
    end
  end
end
