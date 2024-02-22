FactoryBot.define do
  factory :lead_provider do
    name { Faker::Company.unique.name }
    created_at { Faker::Time.between(from: 2.years.ago, to: Time.zone.now) }
    updated_at { created_at }
    ecf_id { Faker::Alphanumeric.alphanumeric(number: 10) }
    hint { Faker::Lorem.sentence }
  end
end
