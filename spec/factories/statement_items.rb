FactoryBot.define do
  factory :statement_item do
    statement { build :statement }
    declaration { build :declaration }
    state { "some_state" }
  end
end
