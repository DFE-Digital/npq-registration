FactoryBot.define do
  factory :course do
    sequence(:name) { |n| "NPQ Course #{n}" }
    identifier { Course::IDENTIFIERS.sample }
    ecf_id { SecureRandom.uuid }
    course_group

    initialize_with do
      Course.find_by(identifier:) || new(**attributes)
    end

    trait :early_headship_coaching_offer do
      sequence(:name) { |n| "NPQ Early Headship Coaching Offer Course #{n}" }
      identifier { "npq-early-headship-coaching-offer" }
      course_group { create(:course_group, name: "ehco") }
    end

    trait :additional_support_offer do
      sequence(:name) { |n| "NPQ Additional Support Offer Course #{n}" }
      identifier { "npq-additional-support-offer" }
      course_group { create(:course_group, name: "support") }
      display { false }
    end

    trait :early_years_leadership do
      sequence(:name) { |n| "NPQ Early Years Leadership Course #{n}" }
      identifier { "npq-early-years-leadership" }
      course_group { create(:course_group, name: "leadership") }
    end

    trait :senior_leadership do
      sequence(:name) { |n| "NPQ Senior Leadership Course #{n}" }
      identifier { "npq-senior-leadership" }
      course_group { create(:course_group, name: "leadership") }
    end

    trait :leading_literacy do
      sequence(:name) { |n| "NPQ Leading Literacy Course #{n}" }
      identifier { "npq-leading-literacy" }
      course_group { create(:course_group, name: "specialist") }
    end

    trait :leading_teaching_development do
      sequence(:name) { |n| "NPQ Leading Teaching Development Course #{n}" }
      identifier { "npq-leading-teaching-development" }
      course_group { create(:course_group, name: "specialist") }
    end

    trait :leading_teaching do
      sequence(:name) { |n| "NPQ Leading Teaching Course #{n}" }
      identifier { "npq-leading-teaching" }
      course_group { create(:course_group, name: "specialist") }
    end

    trait :headship do
      sequence(:name) { |n| "NPQ Headship Course #{n}" }
      identifier { "npq-headship" }
      course_group { create(:course_group, name: "leadership") }
    end

    trait :executive_leadership do
      sequence(:name) { |n| "NPQ Executive Leadership Course #{n}" }
      identifier { "npq-executive-leadership" }
      course_group { create(:course_group, name: "leadership") }
    end

    trait :leading_behaviour_culture do
      sequence(:name) { |n| "NPQ Leading Behaviour Culture Course #{n}" }
      identifier { "npq-leading-behaviour-culture" }
      course_group { create(:course_group, name: "specialist") }
    end

    trait :leading_primary_mathmatics do
      sequence(:name) { |n| "NPQ Leading Primary Mathematics Course #{n}" }
      identifier { "npq-leading-primary-mathematics" }
      course_group { create(:course_group, name: "specialist") }
    end

    trait :senco do
      sequence(:name) { |n| "NPQ for Senco #{n}" }
      identifier { "npq-senco" }
      course_group { create(:course_group, name: "leadership") }
    end

    factory :"npq-executive-leadership", traits: [:executive_leadership]
    factory :"npq-leading-behaviour-culture", traits: [:leading_behaviour_culture]
    factory :"npq-headship", traits: [:headship]
    factory :"npq-leading-teaching", traits: [:leading_teaching]
    factory :"npq-leading-teaching-development", traits: [:leading_teaching_development]
    factory :"npq-leading-literacy", traits: [:leading_literacy]
    factory :"npq-senior-leadership", traits: [:senior_leadership]
    factory :"npq-early-years-leadership", traits: [:early_years_leadership]
    factory :"npq-additional-support-offer", traits: [:additional_support_offer]
    factory :"npq-early-headship-coaching-offer", traits: [:early_headship_coaching_offer]
    factory :"npq-leading-primary-mathematics", traits: [:leading_primary_mathmatics]
    factory :"npq-senco", traits: [:senco]
  end
end
