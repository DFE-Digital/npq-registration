FactoryBot.define do
  factory :statement_item do
    statement { build :statement }
    declaration { build :declaration }
    state { "eligible" }
  end
end
