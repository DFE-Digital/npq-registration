FactoryBot.define do
  factory :declaration do
    application { association(:application) }
    state { "submitted" }
    declaration_type { "some_type" }
    declaration_date { Time.zone.today }
  end
end
