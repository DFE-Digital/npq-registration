FactoryBot.define do
  factory :course do
    sequence(:name) { |n| "NPQ Course #{n}" }
    identifier { Course::IDENTIFIERS.sample }
    ecf_id { SecureRandom.uuid }
    course_group

    initialize_with do
      Course.find_by(identifier:) || new(**attributes)
    end

    trait :ehco do
      sequence(:name) { |n| "NPQ Early Headship Coaching Offer Course #{n}" }
      identifier { "npq-early-headship-coaching-offer" }
      course_group { CourseGroup.find_or_create_by(name: "ehco") }
    end

    trait :aso do
      sequence(:name) { |n| "NPQ Additional Support Offer Course #{n}" }
      identifier { "npq-additional-support-offer" }
      course_group { CourseGroup.find_or_create_by(name: "support") }
      display { false }
    end

    trait :eyl do
      sequence(:name) { |n| "NPQ Early Years Leadership Course #{n}" }
      identifier { "npq-early-years-leadership" }
      course_group { CourseGroup.find_or_create_by(name: "leadership") }
    end

    trait :sl do
      sequence(:name) { |n| "NPQ Senior Leadership Course #{n}" }
      identifier { "npq-senior-leadership" }
      course_group { CourseGroup.find_or_create_by(name: "leadership") }
    end

    trait :ll do
      sequence(:name) { |n| "NPQ Leading Literacy Course #{n}" }
      identifier { "npq-leading-literacy" }
      course_group { CourseGroup.find_or_create_by(name: "specialist") }
    end

    trait :ltd do
      sequence(:name) { |n| "NPQ Leading Teaching Development Course #{n}" }
      identifier { "npq-leading-teaching-development" }
      course_group { CourseGroup.find_or_create_by(name: "specialist") }
    end

    trait :lt do
      sequence(:name) { |n| "NPQ Leading Teaching Course #{n}" }
      identifier { "npq-leading-teaching" }
      course_group { CourseGroup.find_or_create_by(name: "specialist") }
    end

    trait :hs do
      sequence(:name) { |n| "NPQ Headship Course #{n}" }
      identifier { "npq-headship" }
      course_group { CourseGroup.find_or_create_by(name: "leadership") }
    end

    trait :el do
      sequence(:name) { |n| "NPQ Executive Leadership Course #{n}" }
      identifier { "npq-executive-leadership" }
      course_group { CourseGroup.find_or_create_by(name: "leadership") }
    end

    trait :lbc do
      sequence(:name) { |n| "NPQ Leading Behaviour Culture Course #{n}" }
      identifier { "npq-leading-behaviour-culture" }
      course_group { CourseGroup.find_or_create_by(name: "specialist") }
    end

    trait :lpm do
      sequence(:name) { |n| "NPQ Leading Primary Mathematics Course #{n}" }
      identifier { "npq-leading-primary-mathematics" }
      course_group { CourseGroup.find_or_create_by(name: "specialist") }
    end

    trait :senco do
      sequence(:name) { |n| "NPQ for Senco #{n}" }
      identifier { "npq-senco" }
      course_group { CourseGroup.find_or_create_by(name: "leadership") }
    end

    factory :"npq-executive-leadership", traits: [:el]
    factory :"npq-leading-behaviour-culture", traits: [:lbc]
    factory :"npq-headship", traits: [:hs]
    factory :"npq-leading-teaching", traits: [:lt]
    factory :"npq-leading-teaching-development", traits: [:ltd]
    factory :"npq-leading-literacy", traits: [:ll]
    factory :"npq-senior-leadership", traits: [:sl]
    factory :"npq-early-years-leadership", traits: [:eyl]
    factory :"npq-additional-support-offer", traits: [:aso]
    factory :"npq-early-headship-coaching-offer", traits: [:ehco]
    factory :"npq-leading-primary-mathematics", traits: [:lpm]
    factory :"npq-senco", traits: [:senco]
  end
end
