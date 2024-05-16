FactoryBot.define do
  factory :course do
    sequence(:name) { |n| "NPQ Course #{n}" }
    identifier { Course::IDENTIFIERS.sample }
    ecf_id { SecureRandom.uuid }

    initialize_with do
      Course.find_by(identifier:) || new(**attributes)
    end

    trait :ehco do
      sequence(:name) { |n| "NPQ Early Headship Coaching Offer Course #{n}" }
      identifier { "npq-early-headship-coaching-offer" }
    end

    trait :aso do
      sequence(:name) { |n| "NPQ Additional Support Offer Course #{n}" }
      identifier { "npq-additional-support-offer" }
      display { false }
    end

    trait :eyl do
      sequence(:name) { |n| "NPQ Early Years Leadership Course #{n}" }
      identifier { "npq-early-years-leadership" }
    end

    trait :sl do
      sequence(:name) { |n| "NPQ Senior Leadership Course #{n}" }
      identifier { "npq-senior-leadership" }
    end

    trait :ll do
      sequence(:name) { |n| "NPQ Leading Literacy Course #{n}" }
      identifier { "npq-leading-literacy" }
    end

    trait :ltd do
      sequence(:name) { |n| "NPQ Leading Teaching Development Course #{n}" }
      identifier { "npq-leading-teaching-development" }
    end

    trait :lt do
      sequence(:name) { |n| "NPQ Leading Teaching Course #{n}" }
      identifier { "npq-leading-teaching" }
    end

    trait :hs do
      sequence(:name) { |n| "NPQ Headship Course #{n}" }
      identifier { "npq-headship" }
    end

    trait :el do
      sequence(:name) { |n| "NPQ Executive Leadership Course #{n}" }
      identifier { "npq-executive-leadership" }
    end

    trait :lbc do
      sequence(:name) { |n| "NPQ Leading Behaviour Culture Course #{n}" }
      identifier { "npq-leading-behaviour-culture" }
    end

    trait :lpm do
      sequence(:name) { |n| "NPQ Leading Primary Mathematics Course #{n}" }
      identifier { "npq-leading-primary-mathematics" }
    end

    trait :senco do
      sequence(:name) { |n| "NPQ for Senco #{n}" }
      identifier { "npq-senco" }
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
