FactoryBot.define do
  factory :declaration do
    application { association(:application) }
    state { "eligible" }
    declaration_type { "some_type" }
    declaration_date { Time.zone.today }
  end
end
