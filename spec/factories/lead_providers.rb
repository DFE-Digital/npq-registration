FactoryBot.define do
  factory :lead_provider do
    name { Faker::Company.unique.name }
    ecf_id { SecureRandom.uuid }
    hint { Faker::Lorem.sentence }
  end
end
