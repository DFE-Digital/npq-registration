FactoryBot.define do
  factory :statement_item do
    statement
    declaration
    state { "eligible" }

    trait :eligible do
      state { "eligible" }
    end

    trait :payable do
      state { "payable" }
    end

    trait :paid do
      state { "paid" }
    end

    trait :awaiting_clawback do
      state { "awaiting_clawback" }
    end

    trait :clawed_back do
      state { "clawed_back" }
    end
  end
end
