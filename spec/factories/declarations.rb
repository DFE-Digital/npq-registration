FactoryBot.define do
  factory :declaration do
    application { association(:application) }
    state { "submitted" }
  end
end
