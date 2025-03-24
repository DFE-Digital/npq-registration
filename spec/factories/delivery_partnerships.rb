FactoryBot.define do
  factory :delivery_partnership do
    association(:delivery_partner)
    association(:lead_provider)
    cohort { create :cohort, :current }
  end
end
